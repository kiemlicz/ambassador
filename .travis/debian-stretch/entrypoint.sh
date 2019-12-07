#!/usr/bin/env bash

if [ $API_ENABLED = true ]; then
  /usr/bin/salt-api &
  /usr/bin/salt-master &
  wait -n
else
  # replace the bash process with salt-master
  exec /usr/bin/salt-master
fi
