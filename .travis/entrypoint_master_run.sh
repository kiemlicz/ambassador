#!/usr/bin/env bash

# use reactor to accept and start highstate on connected minions
# wait for finish on master then invoke state.orchestrate

curl -o /tmp/bootstrap.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap.sh -M -N stable ${1-""}

# workaround for
# https://github.com/saltstack/salt/issues/37056
#rm -rf /var/run/salt/master/master_event_pub.ipc
#rm -rf /var/run/salt/master/master_event_pull.ipc

/usr/bin/supervisord

python /opt/scan_events.py /var/log/salt/events
