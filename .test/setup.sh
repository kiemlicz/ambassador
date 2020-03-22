#!/usr/bin/env bash

NAME="zeus"
# test nic_opts (if override works, regards ordering)
salt-call --local saltutil.sync_all
salt-call --local lxc.init $NAME profile=debian network_profile=debian bootstrap_args="-x python3"