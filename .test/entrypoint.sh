#!/usr/bin/env bash

apt-get update
apt-get install -y curl
curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap-salt.sh -n -X stable
