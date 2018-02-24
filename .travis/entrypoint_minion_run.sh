#!/usr/bin/env bash

sed -i -e "s/\(^id: \)minion/\1$(hostname -f)/g" /etc/salt/minion.d/minion.conf

# workaround for salt's service state
echo -e '#!/bin/bash\necho "N 5"' > /sbin/runlevel
chmod 775 /sbin/runlevel

/usr/bin/supervisord
