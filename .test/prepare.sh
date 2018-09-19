#!/usr/bin/env bash

report_error() {
    local rv=$?
    #todo attach logs
    echo "Check logs" | mail -s "Test failure" $NOTIFY
    exit $rv
}
trap report_error ERR

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -m|--mail)
        NOTIFY="$2"
        shift
        ;;
        --client_id)
        CLIENT_ID="$2"
        shift
        ;;
        --client_secret)
        CLIENT_SECRET="$2"
        shift
        ;;
        *)
        # unknown option
        ;;
    esac
    shift # past argument or value
done

readonly CONTAINER_MASTER_NAME=tester
readonly CONTAINER_SLAVE_NAME=tested
readonly CONTAINER_MASTER_ROOTFS=/var/lib/lxc/$CONTAINER_MASTER_NAME/rootfs
readonly CONTAINER_SLAVE_ROOTFS=/var/lib/lxc/$CONTAINER_SLAVE_NAME/rootfs

./setup.sh -c --client_id $CLIENT_ID --client_secret $CLIENT_SECRET -u "$USER" -n $CONTAINER_MASTER_NAME

. util/core/text_functions
. util/vm/lxc_functions

AMBASSADOR_LXC_HOST=$(hostname -f)

substenv_file AMBASSADOR .test/config/lxc-provider.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/cloud.providers.d/lxc.conf
substenv_file AMBASSADOR .test/config/lxc-profile.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/cloud.profiles.d/lxc.conf
substenv_file AMBASSADOR .test/config/lxc.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/master.d/lxc.conf

# create test container
create_container config/network.conf $CONTAINER_SLAVE_NAME

#todo provision node
#todo add to cron (should go backgroud or not?)
