#!/usr/bin/env bash

echo "OS version:"
cat /etc/debian_version
echo "starting (args = $@)"

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

service salt-minion restart
#debug may be useful for travis (-l debug)
salt-call --local state.highstate saltenv=$1 pillarenv=$2 -l ${3-info} --no-color --out-file output
echo "salt-call finished"
cat output
echo "scanning output"
awk '/^Failed:/ {if($2 != "0") exit 3}' output

py.test --sudo /opt/infra/$2.py
