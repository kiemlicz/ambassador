#!/usr/bin/env bash

echo "OS version:"
cat /etc/debian_version
echo "starting (args = $@)"

rm /var/log/salt/minion
#so that docker logs will display it
ln -sf /proc/$$/fd/1 /var/log/salt/minion
tail -f /var/log/salt/minion &

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

service salt-minion restart
#debug may be useful for travis (-l debug)
salt-call --local state.highstate saltenv=base pillarenv=one_user -l ${1-info} --out-file output
#travis sometimes cannot handle properly this much of logs
sleep 5
echo "salt-call finished, scanning output"
cat output
sleep 2
cat output | awk '/^Failed:/ {if($2 != "0") exit 3}'
