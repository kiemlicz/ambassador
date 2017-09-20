#!/usr/bin/env bash

rm /var/log/salt/minion
#so that docker logs will display it
ln -sf /proc/$$/fd/1 /var/log/salt/minion
tail -f /var/log/salt/minion &
# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel
service salt-minion restart
#debug may be useful for travis
salt-call --local state.highstate saltenv=base pillarenv=one_user -l debug | tee output
echo "salt-call finished, scanning output"
cat output | awk '/^Failed:/ {if($2 != "0") exit 1}'
