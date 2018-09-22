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
readonly CONTAINER_SLAVE_FQDN="$CONTAINER_SLAVE_NAME.$(dnsdomainname)"
readonly CONTAINER_MASTER_ROOTFS=/var/lib/lxc/$CONTAINER_MASTER_NAME/rootfs
readonly CONTAINER_SLAVE_ROOTFS=/var/lib/lxc/$CONTAINER_SLAVE_NAME/rootfs

./setup.sh -c --client_id $CLIENT_ID --client_secret $CLIENT_SECRET -u "$USER" -n $CONTAINER_MASTER_NAME

. util/core/text_functions
. util/vm/lxc_functions

AMBASSADOR_LXC_HOST=$(hostname -f)

substenv_file AMBASSADOR .test/config/lxc-provider.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/cloud.providers.d/lxc.conf
substenv_file AMBASSADOR .test/config/lxc-profile.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/cloud.profiles.d/lxc.conf
substenv_file AMBASSADOR .test/config/lxc.conf > $CONTAINER_MASTER_ROOTFS/etc/salt/master.d/lxc.conf

# container under test

# create test container
chroot $CONTAINER_SLAVE_ROOTFS sh -c "mkdir /root/.ssh/"
create_container config/network.conf $CONTAINER_SLAVE_NAME
lxc_ensure_ssh_key $USER $CONTAINER_SLAVE_FQDN $CONTAINER_SLAVE_ROOTFS/root
chroot $CONTAINER_SLAVE_ROOTFS sh -c "chown root.root /root/.ssh/authorized_keys; chmod 600 /root/.ssh/authorized_keys"

substenv_file AMBASSADOR .test/config/minion.conf > $CONTAINER_SLAVE_ROOTFS/etc/salt/minion.d/minion.conf

echo "starting: $CONTAINER_SLAVE_NAME"
start_container_waiting_for_network $CONTAINER_SLAVE_NAME

ssh root@$CONTAINER_SLAVE_FQDN -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
    'bash -s' < .test/entrypoint.sh > $CONTAINER_SLAVE_NAME.log 2>&1

echo "containers: $CONTAINER_MASTER_NAME, $CONTAINER_SLAVE_NAME are ready for provisioning"

#todo provision node
#todo add to cron (should go backgroud or not?)
