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
salt_call_ret_val=$?
echo "salt-call finished, exit code: $salt_call_ret_val"
cat output

echo "scanning output"
result=$(awk '/^Failed:/ {if($2 != "0") print "fail"}' output)

if [[ "$result" == "fail" ]] || [[ $salt_call_ret_val -ne 0 ]]; then
    echo "found failures"
    exit 3
fi
