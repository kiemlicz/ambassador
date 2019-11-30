#!/usr/bin/env bash

# runner script - to be run by cron
# as cron clears ENVs the local binaries must be fully qualified

echo "Test started"
readonly test_start_ts=$(date +%s.%N)
pushd /home/vagrant/projects/ambassador

LOGFILE=/var/log/ambassador/amb.kvm.$(date -d "today" +"%Y%m%d%H%M")
touch $LOGFILE
ln -sf $LOGFILE /var/log/ambassador/lastlog

# for manual runs consider https://docs.chef.io/ctl_kitchen.html#id28
# e.g. --destroy=never
BUNDLE_GEMFILE=.test/Gemfile bundle exec /usr/local/bin/kitchen test "$@" >> $LOGFILE 2>&1
result=$?

readonly test_stop_ts=$(date +%s.%N)
readonly test_time=$(echo "$test_stop_ts - $test_start_ts" | bc)

if [[ $result -ne 0 ]]; then
    echo "Test fail, find the logs attached (test time: $test_time)" | mail -A $LOGFILE -s "Ambassador test failed" $(git config user.email)
fi

popd > /dev/null
