#!/usr/bin/env bash

# use reactor to accept and start highstate on connected minions
# wait for finish on master then invoke state.orchestrate

# workaround for
# https://github.com/saltstack/salt/issues/37056
rm -rf /var/run/salt/master/master_event_pub.ipc
rm -rf /var/run/salt/master/master_event_pull.ipc

service salt-master restart

/usr/bin/supervisord
#/bin/bash
