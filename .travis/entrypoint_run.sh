#!/usr/bin/env bash

rm /var/log/salt/minion
#so that docker logs will display it
ln -sf /proc/$$/fd/1 /var/log/salt/minion
tail -f /var/log/salt/minion &
service salt-minion restart
salt-call --local state.highstate saltenv=base pillarenv=one_user -l debug
