#!/usr/bin/env bash

: >> /var/log/salt/minion && tail -f /var/log/salt/minion &
python /opt/envoy_test.py
