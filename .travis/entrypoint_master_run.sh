#!/usr/bin/env bash

# use reactor to accept and start highstate on connected minions
# wait for finish on master then invoke state.orchestrate

/usr/bin/supervisord

python3 /opt/scan_events.py /var/log/salt/events
