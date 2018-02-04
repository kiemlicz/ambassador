#!/usr/bin/env bash

echo "Installing salt-minion, version: $@"

curl -o /tmp/bootstrap.sh -L https://bootstrap.saltstack.com
sh /tmp/bootstrap.sh stable ${1-""}

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

#service salt-minion restart

/usr/bin/supervisord
