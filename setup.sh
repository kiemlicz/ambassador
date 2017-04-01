#!/usr/bin/env bash

# Builds foreman + salt inside LXC container, configures them fully
# Arguments:
# -c generate certificates, without this option create 'ssl' dir (in container directory) with ca, key+cert (signed by ca)
# -n container name

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -c|--cert-gen)
        GEN_CERT=true
        ;;
        -n|--name)
        CN="$2"
        shift # past argument
        ;;
        --ca)
        CA_CERT_FILE="$2"
        shift # past argument
        ;;
        --cert)
        SERVER_CERT_FILE="$2"
        shift # past argument
        ;;
        --key)
        SERVER_KEY_FILE="$2"
        shift # past argument
        ;;
        --crl)
        CRL_FILE="$2"
        shift # past argument
        ;;
        --deploy_priv)
        DEPLOY_PRIV_FILE="$2"
        shift
        ;;
        --deploy_pub)
        DEPLOY_PUB_FILE="$2"
        shift
        ;;
        *)
        # unknown option
        ;;
    esac
    shift # past argument or value
done

readonly AUTO_CERT_GENERATION=${GEN_CERT-false}
readonly CONTAINER_NAME=${CN-ambassador}
readonly CONTAINER_CERT_BASE=/etc/foreman/ssl
readonly CONTAINER_CERT_DIR=$CONTAINER_CERT_BASE/certs
readonly CONTAINER_PRIVATE_DIR=$CONTAINER_CERT_BASE/private

##### validate
#expand to bash array for easier validation
all_containers_array=($(lxc-ls))
for container_name in "${all_containers_array[@]}"; do
    if [[ $container_name == $CONTAINER_NAME ]]; then
        echo "container with name: $CONTAINER_NAME already exists, exiting"
        exit 1
    fi
done

if [ "$AUTO_CERT_GENERATION" = false ] && ([ -z $CA_CERT_FILE ] || [ -z $SERVER_CERT_FILE ] || [ -z $SERVER_KEY_FILE ] || [ -z $CRL_FILE ]); then
    echo "Provide all: ca cert, server cert, server key and crl file or use auto-generation method"
    exit 1
fi

if ([ -z $DEPLOY_PUB_FILE ] || [ -z $DEPLOY_PRIV_FILE ]); then
    echo "Not using salt repo keypair (in order to enable, use: --deploy_pub <location>, --deploy_priv <location>)"
else
    if ! ([ -f $DEPLOY_PUB_FILE ] && [ -f $DEPLOY_PRIV_FILE ]); then
        echo "Provided keypair not found in filesystem"
        exit 1
    fi
fi

if [ -z "$(dnsdomainname)" ]; then
    echo "Unable to determine domain name"
    exit 1
fi

readonly CONTAINER_FQDN="$CONTAINER_NAME.$(dnsdomainname)"
readonly CONTAINER_ROOTFS=/var/lib/lxc/$CONTAINER_NAME/rootfs

##### build container
. util/vm/lxc_functions

lxc-create -f container/network.conf -t ubuntu -n $CONTAINER_NAME -- -r xenial -a amd64
retval=$?
if [ $retval -ne 0 ]; then
    echo "error creating container: $retval"
    exit 1
fi

chroot $CONTAINER_ROOTFS sh -c "echo 'ubuntu ALL=NOPASSWD:ALL' > /etc/sudoers.d/ubuntu; chmod 440 /etc/sudoers.d/ubuntu"
#todo how to achieve passwordless sudo -u postgres, below doesn't work
#chroot $CONTAINER_ROOTFS sh -c "echo 'postgres ALL=NOPASSWD:ALL' > /etc/sudoers.d/postgres; chmod 440 /etc/sudoers.d/postgres"
chroot $CONTAINER_ROOTFS sh -c \
    "echo 'Cmnd_Alias SALT = /usr/bin/salt, /usr/bin/salt-key\nforeman-proxy ALL = NOPASSWD: SALT\nDefaults:foreman-proxy !requiretty' > /etc/sudoers.d/salt; chmod 440 /etc/sudoers.d/salt"
echo "passwordless sudo enabled for ubuntu user"

# remove accepting locale on server so that no locale generation is needed
chroot $CONTAINER_ROOTFS sh -c "sed -i -e 's/\(^AcceptEnv LANG.*\)/#\1/g' /etc/ssh/sshd_config"
chroot $CONTAINER_ROOTFS sh -c "sed -i '/^127.0.1.1 /s/$CONTAINER_NAME/$CONTAINER_FQDN $CONTAINER_NAME/' /etc/hosts"
#configure resolvconf utility so that proper nameserver exists, otherwise only 127.0.0.1 may appear
chroot $CONTAINER_ROOTFS sh -c "echo 'TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=no' > /etc/default/resolvconf"

if [ "$AUTO_CERT_GENERATION" = true ]; then
    . util/sec/cert_functions
    SSL_BASE=$CONTAINER_ROOTFS/$CONTAINER_CERT_BASE
    mkdir -p $CONTAINER_ROOTFS/$CONTAINER_CERT_DIR
    mkdir -p $CONTAINER_ROOTFS/$CONTAINER_PRIVATE_DIR
    #further ssl/ca-certificates installation doesn't clear /etc/ssl/private/certs contents
    echo "generating ca, certs: $SSL_BASE"
    touch $SSL_BASE/index.txt
    echo '01' > $SSL_BASE/serial.txt
    CA_PK_FILE=$CONTAINER_ROOTFS/$CONTAINER_PRIVATE_DIR/ca.key
    CA_CERT_FILE=$CONTAINER_ROOTFS/$CONTAINER_CERT_DIR/ca.pem
    SERVER_KEY_FILE=$CONTAINER_ROOTFS/$CONTAINER_PRIVATE_DIR/$CONTAINER_FQDN.key
    SERVER_CERT_FILE=$CONTAINER_ROOTFS/$CONTAINER_CERT_DIR/$CONTAINER_FQDN.pem
    CRL_FILE=$SSL_BASE/crl.pem
    gen_rsa_key $CA_PK_FILE
    CA_PK_FILE=$CA_PK_FILE gen_x509_cert_self_signed $CA_PK_FILE $CA_CERT_FILE util/sec/openssl-ca.cnf
    echo "ca generation done, generating server secrets"
    SSL_BASE=$SSL_BASE gen_crl_nonstd $CA_PK_FILE $CA_CERT_FILE $CRL_FILE util/sec/openssl-ca-signing.cnf
    gen_rsa_key $SERVER_KEY_FILE
    SERVER_KEY_FILE=$SERVER_KEY_FILE SERVER_FQDN=$CONTAINER_FQDN gen_csr $SERVER_KEY_FILE /tmp/$CONTAINER_FQDN.csr util/sec/openssl-server.cnf
    echo "signing server's csr"
    SSL_BASE=$SSL_BASE gen_csr_sign /tmp/$CONTAINER_FQDN.csr $SERVER_CERT_FILE util/sec/openssl-ca-signing.cnf
else
    echo "copying certificates into container fs: $CONTAINER_ROOTFS"
    cp $CA_CERT_FILE $CONTAINER_ROOTFS/$CONTAINER_CERT_DIR
    cp $SERVER_CERT_FILE $CONTAINER_ROOTFS/$CONTAINER_CERT_DIR
    cp $SERVER_KEY_FILE $CONTAINER_ROOTFS/$CONTAINER_PRIVATE_DIR
    cp $CRL_FILE $CONTAINER_ROOTFS/$CONTAINER_CERT_BASE
fi

. util/core/text_functions

mkdir -p $CONTAINER_ROOTFS/etc/salt/deploykeys/
mkdir -p $CONTAINER_ROOTFS/etc/salt/master.d/
mkdir -p $CONTAINER_ROOTFS/etc/foreman-proxy/settings.d/
mkdir -p $CONTAINER_ROOTFS/etc/dnsmasq.d/
mkdir -p $CONTAINER_ROOTFS/srv/salt_ext/

AMBASSADOR_CA=$CONTAINER_CERT_DIR/$(basename $CA_CERT_FILE)
AMBASSADOR_CRL=$CONTAINER_CERT_BASE/$(basename $CRL_FILE)
AMBASSADOR_KEY=$CONTAINER_PRIVATE_DIR/$(basename $SERVER_KEY_FILE)
AMBASSADOR_CERT=$CONTAINER_CERT_DIR/$(basename $SERVER_CERT_FILE)
AMBASSADOR_GW=$(ip route get 8.8.8.8 | head -n1 | cut -d' ' -f3)
AMBASSADOR_SALT_API_PORT=9191
AMBASSADOR_SALT_API_INTERFACES=0.0.0.0
AMBASSADOR_FQDN=$CONTAINER_FQDN
if ! ([ -z $DEPLOY_PUB_FILE ] || [ -z $DEPLOY_PRIV_FILE ]); then
    AMBASSADOR_ENVOY_DEPLOY_PUB=$(basename $DEPLOY_PUB_FILE)
    AMBASSADOR_ENVOY_DEPLOY_PRIV=$(basename $DEPLOY_PRIV_FILE)
    #copy keys to container
    cp $DEPLOY_PUB_FILE $CONTAINER_ROOTFS/etc/salt/deploykeys/
    cp $DEPLOY_PRIV_FILE $CONTAINER_ROOTFS/etc/salt/deploykeys/
fi

#copy dependencies to container
cp -r envoy/extensions/pillar/ $CONTAINER_ROOTFS/srv/salt_ext/

#fill templates and copy to container
substenv_file AMBASSADOR config_files/ambassador_salt.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_salt.conf
substenv_file AMBASSADOR config_files/foreman.yaml > $CONTAINER_ROOTFS/etc/salt/foreman.yaml
substenv_file AMBASSADOR config_files/salt.yml > $CONTAINER_ROOTFS/etc/foreman-proxy/settings.d/salt.yml
substenv_file AMBASSADOR config_files/proxydhcp.conf > $CONTAINER_ROOTFS/etc/dnsmasq.d/proxydhcp.conf

#todo use /etc/ssl dir? ubuntu user add to ssl-cert group ?
echo "starting: $CONTAINER_NAME"
# -f (for lxc-start) not needed as during creation the option got persisted
start_container_waiting_for_network $CONTAINER_NAME
echo "container running"

readonly CONTAINER_IP=$(lxc-info -n $CONTAINER_NAME -i | cut -d: -f2 | sed -e 's/ //g')

if [ -z "$CONTAINER_IP" ]; then
    echo "cannot resolve IP (domain = $CONTAINER_FQDN, IP = $CONTAINER_IP) for container, exiting"
    exit 1
fi
#this node (running setup.sh script) doesn't add ambassador to known hosts
#as doing so will cause repeating "Host Verification Failed"
echo "running 'run' script inside container (IP = $CONTAINER_IP, DOMAIN=$CONTAINER_FQDN)"
ssh ubuntu@$CONTAINER_IP -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
    CIP=$CONTAINER_IP CID=$CONTAINER_FQDN CERT_BASEDIR=$CONTAINER_CERT_BASE CA=$AMBASSADOR_CA CRL=$AMBASSADOR_CRL KEY=$AMBASSADOR_KEY CERT=$AMBASSADOR_CERT \
    'bash -s' < ./run.sh
retval=$?
echo "stopping container"
stop_container $CONTAINER_NAME

if [ $retval -ne 0 ]; then
    echo "error running run.sh script inside of container: $retval"
    exit 1
else
    echo "success"
fi
