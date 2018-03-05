#!/usr/bin/env bash

# use reactor to accept and start highstate on connected minions
# wait for finish on master then invoke state.orchestrate

salt-run saltutil.sync_renderers
/usr/bin/supervisord

python /opt/scan_events.py /var/log/salt/events
