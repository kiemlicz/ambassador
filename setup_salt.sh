#!/usr/bin/env bash

readonly SALTSTACK_STRETCH_REPO_URL="deb http://repo.saltstack.com/apt/debian/9/amd64/latest stretch main"
readonly SALTSTACK_STRETCH_REPO_KEY_URL="https://repo.saltstack.com/apt/debian/9/amd64/latest/SALTSTACK-GPG-KEY.pub"

readonly SALTSTACK_REPO_ENTRY=$SALTSTACK_STRETCH_REPO_URL
readonly SALTSTACK_REPO_KEY=$SALTSTACK_STRETCH_REPO_KEY_URL

apt-get update
apt-get upgrade -y -o DPkg::Options::=--force-confold
apt-get install -y ca-certificates wget host curl gnupg2 sudo apt-transport-https

wget -O - $SALTSTACK_REPO_KEY | apt-key add -
echo "$SALTSTACK_REPO_ENTRY" | tee /etc/apt/sources.list.d/saltstack.list

apt-get update
apt-get install -y salt-master salt-api salt-ssh python-pip python-pygit2 tcpdump nano vim

#check that libgit2 is properly built
#there is bug that breaks https connection in git
#https://bugs.launchpad.net/ubuntu/+source/libgit2/+bug/1595565
if [ $(python -c "import pygit2; print(bool(pygit2.features & pygit2.GIT_FEATURE_HTTPS))") == "False" ]; then
    echo "detected improper version of pygit2, fixing..."
    apt-get purge -y python-pygit2 libgit2-24 python-cffi
    pip uninstall -y cffi || true # pip uninstall for not installed package will fail the build due to `set -e`
    apt-get install -y pkg-config libcurl3-dev libssh2-1-dev build-essential cmake libssl-dev libffi-dev zlib1g-dev
    libgit_ver=0.27.0
    pushd /tmp
    wget https://github.com/libgit2/libgit2/archive/v$libgit_ver.tar.gz
    tar xzf /tmp/v$libgit_ver.tar.gz
    pushd libgit2-$libgit_ver
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
        echo "Unable to properly configure pygit2 (missing HTTPS support)"
        exit 1
    fi
    if [ $(python -c "import pygit2; print(bool(pygit2.features & pygit2.GIT_FEATURE_SSH))") == "False" ]; then
        echo "Unable to properly configure pygit2 (missing SSH support)"
        exit 1
    fi
fi

#todo use pip install --user and add to PATH ~/.local/bin
#somehow these dependencies are already present, that's why use of --upgrade
#as long as this is not released https://github.com/saltstack/salt/issues/44601 CherryPy max supported version is 11.2.0
pip install --upgrade docker-py cherrypy jinja2 Flask eventlet PyYAML flask-socketio requests_oauthlib google-auth
#pip 10 is not backward compatible
#pip install --upgrade pip

# makes gitfs work...
salt-run fileserver.clear_cache

#rebind to new hostname (LXC could have obtained the address using old hostname)
dhclient -r
dhclient eth0

systemctl enable salt-master salt-api
systemctl restart salt-master salt-api
