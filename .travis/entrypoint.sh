#!/usr/bin/env bash

tail -f /var/log/salt/master &
python /opt/envoy_test.py
