#!/usr/bin/env bash

#to be run inside of container
#sets up foreman & salt
#
#arguments:
#CID container fqdn
#CIP container IP
#CA
#CRL
#CERT
#KEY
#CERT_BASEDIR

assert_env() {
    if [ -z $2 ]; then
        echo "$1"
        exit 1
    fi
}

assert_env "fqdn is not set" $CID
assert_env "container designated IP is not provided" $CIP
assert_env "CA is not set" $CA
assert_env "CRL is not set" $CRL
assert_env "CERT is not set" $CERT
assert_env "KEY is not set" $KEY
assert_env "CERT_BASEDIR is not set" $CERT_BASEDIR

#edit versions
readonly FOREMAN_XENIAL_REPO_URL="deb http://deb.theforeman.org/ xenial 1.15"
readonly FOREMAN_XENIAL_PLUGINS_REPO_URL="deb http://deb.theforeman.org/ plugins 1.15"
readonly FOREMAN_XENIAL_REPO_KEY="https://deb.theforeman.org/pubkey.gpg"
readonly PUPPET_SERVER_PKG="puppetlabs-release-pc1-yakkety.deb"
readonly FOREMAN_XENIAL_PUPPET_SERVER="https://apt.puppetlabs.com/$PUPPET_SERVER_PKG"
readonly SALTSTACK_XENIAL_REPO_URL="deb http://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest xenial main"
readonly SALTSTACK_XENIAL_REPO_KEY_URL="https://repo.saltstack.com/apt/ubuntu/16.04/amd64/latest/SALTSTACK-GPG-KEY.pub"

#don't edit these
readonly FOREMAN_PUPPET_SERVER=$FOREMAN_XENIAL_PUPPET_SERVER
readonly FOREMAN_REPO_ENTRY=$FOREMAN_XENIAL_REPO_URL
readonly FOREMAN_PLUGINS_REPO_ENTRY=$FOREMAN_XENIAL_PLUGINS_REPO_URL
readonly FOREMAN_REPO_KEY=$FOREMAN_XENIAL_REPO_KEY
readonly SALTSTACK_REPO_ENTRY=$SALTSTACK_XENIAL_REPO_URL
readonly SALTSTACK_REPO_KEY=$SALTSTACK_XENIAL_REPO_KEY_URL

apt-get update
apt-get upgrade -y -o DPkg::Options::=--force-confold
apt-get install -y ca-certificates wget host curl

wget -P /tmp/ $FOREMAN_PUPPET_SERVER && dpkg -i /tmp/$PUPPET_SERVER_PKG
retval=$?
# assignment so that it's a bit more clear that we need to check $? (which follows last executed command so it's easy
# to add here something different, like echo, and $? changes...)
if [ $retval -ne 0 ]; then
    echo "error installing puppet"
    exit 1
fi
wget -O - $SALTSTACK_REPO_KEY | apt-key add -
wget -q $FOREMAN_REPO_KEY -O- | apt-key add -

echo "$SALTSTACK_REPO_ENTRY" | tee /etc/apt/sources.list.d/saltstack.list
echo "$FOREMAN_REPO_ENTRY" | tee /etc/apt/sources.list.d/foreman.list
echo "$FOREMAN_PLUGINS_REPO_ENTRY" | tee -a /etc/apt/sources.list.d/foreman.list

# Install Salt and Foreman
apt-get update
apt-get install -y salt-master salt-api python-pip python-pygit2 foreman-installer dnsmasq tcpdump
#for UEFI support via proxyDHCP the minimum dnsmasq version is 2.76
pip install --upgrade pip

#check that libgit2 is properly built
#there is bug that breaks https connection in git
#https://bugs.launchpad.net/ubuntu/+source/libgit2/+bug/1595565
if [ $(python -c "import pygit2; print(bool(pygit2.features & pygit2.GIT_FEATURE_HTTPS))") == "False" ]; then
    echo "detected improper version of pygit2, fixing..."
    apt-get purge -y python-pygit2 libgit2-24 python-cffi
    yes |  pip uninstall cffi
    apt-get install -y pkg-config libcurl3-dev libssh2-1-dev build-essential cmake libssl-dev libffi-dev

    pushd /tmp
    wget https://github.com/libgit2/libgit2/archive/v0.25.0.tar.gz
    tar xzf /tmp/v0.25.0.tar.gz
    pushd libgit2-0.25.0
    cmake .
    make
    make install
    popd
    popd
    ldconfig

    pip install --upgrade pyOpenSSL pygit2
    retval=$?
    if [ $retval -ne 0 ]; then
        echo "there were fatal errors during foreman installation (pygit2 workaround)"
        exit 1
    fi
    if [ $(python -c "import pygit2; print(bool(pygit2.features & pygit2.GIT_FEATURE_HTTPS))") == "False" ]; then
        echo "Unable to properly configure pygit2"
        exit 1
    fi
fi

#todo use pip install --user and add to PATH ~/.local/bin
#somehow these dependencies are already present, that's why use of --upgrade
pip install --upgrade docker-py cherrypy

useradd -r saltuser
echo 'saltuser:saltpassword' | chpasswd

CIF=$(cat /etc/resolv.conf | egrep -v '(127.0.0.1)|(127.0.1.1)' | egrep -m 1 '^nameserver.+' | cut -d' ' -f2)

if [[ $CIF == "127.0.0.1" ]]; then
    echo "improper dns forwarder address (CIF=127.0.0.1)"
    exit 1
fi

readonly CA_CERT=$CA
readonly FOREMAN_CRL=$CRL
readonly FOREMAN_CERT=$CERT
readonly FOREMAN_KEY=$KEY

echo "running foreman-installer (nameserver=$CIF, domain=$(dnsdomainname), fqdn=$CID, IP=$CIP)"
#install process divided into two steps as oauth token needs to be present for PXE and salt setup
#http://projects.theforeman.org/issues/16241
#https://theforeman.org/manuals/1.12/index.html#3.2.3InstallationScenarios
#disabling puppet requires user to provide certificate with key and ca certificate
foreman-installer \
    --no-enable-puppet \
    --puppet-server=false \
    --foreman-proxy-puppet=false \
    --foreman-proxy-puppetca=false \
    --foreman-user-groups=EMPTY_ARRAY \
    --foreman-proxy-puppet-group=$(whoami) \
    --foreman-server-ssl-ca=$CA_CERT \
    --foreman-server-ssl-chain=$CA_CERT \
    --foreman-server-ssl-cert=$FOREMAN_CERT \
    --foreman-server-ssl-key=$FOREMAN_KEY \
    --foreman-server-ssl-crl=$FOREMAN_CRL \
    --foreman-client-ssl-ca=$CA_CERT \
    --foreman-client-ssl-cert=$FOREMAN_CERT \
    --foreman-client-ssl-key=$FOREMAN_KEY \
    --foreman-websockets-ssl-cert=$FOREMAN_CERT \
    --foreman-websockets-ssl-key=$FOREMAN_KEY \
    --foreman-proxy-ssl-ca=$CA_CERT \
    --foreman-proxy-ssl-cert=$FOREMAN_CERT \
    --foreman-proxy-ssl-key=$FOREMAN_KEY \
    --foreman-proxy-ssldir=$CERT_BASEDIR \
    --puppet-ssldir=$CERT_BASEDIR \
    --foreman-puppet-ssldir=$CERT_BASEDIR \
    --foreman-proxy-puppet-ssl-ca=$CA_CERT \
    --foreman-proxy-puppet-ssl-cert=$FOREMAN_CERT \
    --foreman-proxy-puppet-ssl-key=$FOREMAN_KEY

echo "enabling further foreman options"
readonly OAUTH_KEY=$(cat /etc/foreman/settings.yaml | grep :oauth_consumer_key: | cut -d' ' -f2)
readonly OAUTH_SECRET=$(cat /etc/foreman/settings.yaml | grep :oauth_consumer_secret: | cut -d' ' -f2)

# salt integration based on:
# https://theforeman.org/plugins/foreman_salt/7.0/index.html
# in order to support more "host types", see:
# https://theforeman.org/manuals/1.12/index.html#5.2ComputeResources
readonly CRED=$(foreman-installer \
    --enable-foreman-proxy \
    --foreman-proxy-tftp=true \
    --foreman-proxy-tftp-servername=$CIP \
    --foreman-proxy-dns=true \
    --foreman-proxy-dns-interface=$(ip route get 8.8.8.8 | head -n1 | cut -d' ' -f5) \
    --foreman-proxy-dns-zone=$(dnsdomainname) \
    --foreman-proxy-dns-reverse=$(host -i $CIP | cut -d' ' -f1 | cut -d. -f2-7) \
    --foreman-proxy-dns-forwarders=$CIF \
    --foreman-proxy-foreman-base-url=https://$CID \
    --foreman-proxy-oauth-consumer-key=$OAUTH_KEY \
    --foreman-proxy-oauth-consumer-secret=$OAUTH_SECRET \
    --enable-foreman-plugin-remote-execution \
    --enable-foreman-proxy-plugin-remote-execution-ssh \
    --enable-foreman-plugin-discovery \
    --enable-foreman-proxy-plugin-discovery \
    --enable-foreman-plugin-salt \
    --enable-foreman-proxy-plugin-salt \
    --foreman-proxy-plugin-salt-api=true \
    --foreman-proxy-plugin-salt-api-url=https://$CID:9191 | sed -n 's/.*Initial credentials are \([[:alpha:]]*\) \/ \([[:alnum:]]*\)/\1:\2/p')

readonly FOREMAN_GUI_USER=$(echo "$CRED" | cut -d: -f1)
readonly FOREMAN_GUI_PASSWORD=$(echo "$CRED" | cut -d: -f2)

retval=$?
if [ $retval -ne 0 ]; then
    echo "there were errors during foreman installation, not breaking as some of them are non-fatal"
fi

echo "populating salt&foreman config files"
touch /etc/salt/autosign.conf
chgrp foreman-proxy /etc/salt/autosign.conf
chmod g+w /etc/salt/autosign.conf

systemctl enable foreman foreman-proxy salt-master salt-api dnsmasq
systemctl restart foreman foreman-proxy salt-master salt-api dnsmasq foreman-tasks

echo "User: $FOREMAN_GUI_USER"
echo "Password: $FOREMAN_GUI_PASSWORD"
