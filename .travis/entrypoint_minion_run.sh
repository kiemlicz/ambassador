#!/usr/bin/env bash

echo "Installing salt-minion, version: $@"

curl -o /tmp/bootstrap.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap.sh -n -X stable ${1-""}

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

ln -sf /dev/stdout /var/log/salt/minion

/usr/bin/supervisord
