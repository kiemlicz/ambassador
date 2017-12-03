#!/usr/bin/env bash

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

service salt-minion restart

echo "starting minion"
/usr/bin/supervisord
