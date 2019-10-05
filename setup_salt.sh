#!/usr/bin/env bash

readonly SALTSTACK_STRETCH_REPO_URL="deb http://repo.saltstack.com/py3/debian/9/amd64/latest stretch main"
readonly SALTSTACK_STRETCH_REPO_KEY_URL="https://repo.saltstack.com/py3/debian/9/amd64/latest/SALTSTACK-GPG-KEY.pub"

readonly SALTSTACK_REPO_ENTRY=$SALTSTACK_STRETCH_REPO_URL
readonly SALTSTACK_REPO_KEY=$SALTSTACK_STRETCH_REPO_KEY_URL

wget -O - $SALTSTACK_REPO_KEY | apt-key add -
echo "$SALTSTACK_REPO_ENTRY" | tee /etc/apt/sources.list.d/saltstack.list

apt-get update
apt-get install -y "$@"

#rebind to new hostname (LXC could have obtained the address using old hostname)
dhclient -r
dhclient eth0

systemctl enable "$@" || true
systemctl restart "$@" || true
