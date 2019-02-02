#!/usr/bin/env bash

readonly SALTSTACK_STRETCH_REPO_URL="deb http://repo.saltstack.com/apt/debian/9/amd64/latest stretch main"
readonly SALTSTACK_STRETCH_REPO_KEY_URL="https://repo.saltstack.com/apt/debian/9/amd64/latest/SALTSTACK-GPG-KEY.pub"
readonly BACKPORTS_REPO="deb http://ftp.debian.org/debian stretch-backports main"

readonly SALTSTACK_REPO_ENTRY=$SALTSTACK_STRETCH_REPO_URL
readonly SALTSTACK_REPO_KEY=$SALTSTACK_STRETCH_REPO_KEY_URL

apt-get update
apt-get upgrade -y -o DPkg::Options::=--force-confold
apt-get install -y ca-certificates wget host curl gnupg2 sudo apt-transport-https libffi-dev git python-pip zlib1g-dev

wget -O - $SALTSTACK_REPO_KEY | apt-key add -
echo "$SALTSTACK_REPO_ENTRY" | tee /etc/apt/sources.list.d/saltstack.list
echo "$BACKPORTS_REPO" | tee /etc/apt/sources.list.d/backports.list

apt-get update
apt-get install -t stretch-backports -y libgit2-dev
#old 'compilation' process can be found here: https://gist.github.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a
#curl -L https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/b9aba40aa30f238a24fe4ecb4ddc1650d9d685af/init.sh | bash
apt-get install -y salt-master salt-api salt-ssh tcpdump nano vim

#somehow these dependencies are already present, that's why use of --upgrade
#as long as this is not released https://github.com/saltstack/salt/issues/44601 CherryPy max supported version is 11.2.0
pip install --upgrade pyOpenSSL pygit2==0.27.3 docker-py cherrypy jinja2 Flask eventlet PyYAML flask-socketio requests_oauthlib google-auth
#pip 10 is not backward compatible
#pip install --upgrade pip

#rebind to new hostname (LXC could have obtained the address using old hostname)
dhclient -r
dhclient eth0

systemctl enable salt-master salt-api
systemctl restart salt-master salt-api
