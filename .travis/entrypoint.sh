#!/usr/bin/env bash

tail -f /var/log/salt/minion &
python /opt/envoy_test.py
