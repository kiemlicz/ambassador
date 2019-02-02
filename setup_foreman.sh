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

set -e

assert_env() {
    if [ -z $2 ]; then
        echo "$1"
        exit 1
    fi
}

assert_env "fqdn is not set" $CID
assert_env "CA is not set" $CA
assert_env "CRL is not set" $CRL
assert_env "CERT is not set" $CERT
assert_env "PROXY_CERT is not set" $PROXY_CERT
assert_env "KEY is not set" $KEY
assert_env "PROXY_KEY is not set" $PROXY_KEY
assert_env "CERT_BASEDIR is not set" $CERT_BASEDIR
assert_env "SALT_USER is not set" $SALT_USER
assert_env "SALT_PASSWORD is not set" $SALT_PASSWORD

#edit versions
readonly FOREMAN_STRETCH_REPO_URL="deb http://deb.theforeman.org/ stretch 1.20"
readonly FOREMAN_STRETCH_PLUGINS_REPO_URL="deb http://deb.theforeman.org/ plugins 1.20"
readonly FOREMAN_STRETCH_REPO_KEY="https://deb.theforeman.org/pubkey.gpg"
readonly PUPPET_STRETCH_SERVER_PKG="puppet5-release-stretch.deb"
readonly FOREMAN_PUPPET_SERVER_URL="https://apt.puppetlabs.com"

#don't edit these
readonly CIP=${CIP-$(ip r s | grep "scope link src" | cut -d' ' -f9)}
readonly PUPPET_SERVER_PKG=$PUPPET_STRETCH_SERVER_PKG
readonly FOREMAN_PUPPET_SERVER=$FOREMAN_PUPPET_SERVER_URL/$PUPPET_SERVER_PKG
readonly FOREMAN_REPO_ENTRY=$FOREMAN_STRETCH_REPO_URL
readonly FOREMAN_PLUGINS_REPO_ENTRY=$FOREMAN_STRETCH_PLUGINS_REPO_URL
readonly FOREMAN_REPO_KEY=$FOREMAN_STRETCH_REPO_KEY

apt-get update
apt-get upgrade -y -o DPkg::Options::=--force-confold
apt-get install -y ca-certificates wget host curl gnupg2 sudo apt-transport-https

#ensure en_US.UTF-8 locale is present, foreman installer requires it
sed -i -e 's/^#\(.*en_US.UTF-8 UTF-8.*\)/\1/g' /etc/locale.gen
locale-gen

wget -P /tmp/ $FOREMAN_PUPPET_SERVER && dpkg -i /tmp/$PUPPET_SERVER_PKG
retval=$?
# assignment so that it's a bit more clear that we need to check $? (which follows last executed command so it's easy
# to add here something different, like echo, and $? changes...)
if [ $retval -ne 0 ]; then
    echo "error installing puppet"
    exit 1
fi
wget -q $FOREMAN_REPO_KEY -O- | apt-key add -

echo "$FOREMAN_REPO_ENTRY" | tee /etc/apt/sources.list.d/foreman.list
echo "$FOREMAN_PLUGINS_REPO_ENTRY" | tee -a /etc/apt/sources.list.d/foreman.list

# Install Salt and Foreman
apt-get update
apt-get install -y foreman-installer dnsmasq tcpdump nano vim
#for UEFI support via proxyDHCP the minimum dnsmasq version is 2.76

#api user for foreman
useradd -r saltuser
echo "$SALT_USER:$SALT_PASSWORD" | chpasswd

CIF=$(cat /etc/resolv.conf | egrep -v '(127.0.0.1)|(127.0.1.1)' | egrep -m 1 '^nameserver.+' | cut -d' ' -f2)

if [[ $CIF == "127.0.0.1" ]]; then
    echo "improper dns forwarder address (CIF=127.0.0.1)"
    exit 1
fi

readonly CA_CERT=$CA
readonly FOREMAN_CRL=$CRL
readonly FOREMAN_CERT=$CERT
readonly FOREMAN_KEY=$KEY
readonly FOREMAN_PROXY_CERT=$PROXY_CERT
readonly FOREMAN_PROXY_KEY=$PROXY_KEY

groupadd foreman
chgrp foreman $FOREMAN_PROXY_KEY $FOREMAN_KEY
chmod 640 $FOREMAN_KEY
chmod 640 $FOREMAN_PROXY_KEY

mkdir -p /var/lib/foreman-proxy

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
    --foreman-proxy-puppet-group=foreman \
    --foreman-user-groups=EMPTY_ARRAY \
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
    --foreman-proxy-ssl-cert=$FOREMAN_PROXY_CERT \
    --foreman-proxy-ssl-key=$FOREMAN_PROXY_KEY \
    --foreman-proxy-ssldir=$CERT_BASEDIR

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
    --enable-foreman-compute-libvirt \
    --enable-foreman-plugin-salt \
    --enable-foreman-proxy-plugin-salt \
    --foreman-proxy-plugin-salt-api=true \
    --foreman-proxy-plugin-salt-api-url=https://$CID:9191 \
    --enable-foreman-cli-remote-execution \
    --enable-foreman-plugin-remote-execution \
    --enable-foreman-proxy-plugin-remote-execution-ssh \
    --enable-foreman-plugin-discovery \
    --enable-foreman-proxy-plugin-discovery | sed -n 's/.*Initial credentials are \([[:alpha:]]*\) \/ \([[:alnum:]]*\)/\1:\2/p')

#this plugin causes a lot of problems, sometimes it's better to disable
#foreman-installer \
#    --enable-foreman-cli-remote-execution \
#    --enable-foreman-plugin-remote-execution \
#    --enable-foreman-proxy-plugin-remote-execution-ssh

readonly FOREMAN_GUI_USER=$(echo "$CRED" | cut -d: -f1)
readonly FOREMAN_GUI_PASSWORD=$(echo "$CRED" | cut -d: -f2)

echo "populating salt&foreman config files"
touch /etc/salt/autosign.conf
chgrp foreman-proxy /etc/salt/autosign.conf
chmod g+w /etc/salt/autosign.conf

echo "enabling http resource provider"
mv /var/tmp/30-saltfs.conf /etc/apache2/sites-available/
a2ensite 30-saltfs

echo "generating foreman keys"
mkdir -p /usr/share/foreman/.ssh
chmod 700 /usr/share/foreman/.ssh
chown foreman:foreman /usr/share/foreman/.ssh
sudo -u foreman bash << EOF
    echo -e "\n" | ssh-keygen -t rsa -N ""
EOF
#authorize foreman to KVM host
#su foreman -s /bin/bash
#ssh-copy-id user@KVM_host

#rebind to new hostname (LXC could have obtained the address using old hostname)
dhclient -r
dhclient eth0

systemctl enable foreman foreman-proxy dynflowd dnsmasq file_ext_authorize
systemctl restart foreman foreman-proxy dynflowd dnsmasq file_ext_authorize ruby-foreman-tasks

echo "User: $FOREMAN_GUI_USER"
echo "Password: $FOREMAN_GUI_PASSWORD"
