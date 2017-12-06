#!/usr/bin/env bash

curl -L https://bootstrap.saltstack.com | sh

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

service salt-minion restart

/usr/bin/supervisord
