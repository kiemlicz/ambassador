#!/usr/bin/env bash

if [ $API_ENABLED = true ]; then
  /usr/local/bin/salt-api &
  /usr/local/bin/salt-master &
  wait -n
else
  # replace the bash process with salt-master
  exec /usr/local/bin/salt-master
fi
