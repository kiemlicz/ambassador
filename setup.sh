#!/usr/bin/env bash

# Builds foreman + salt inside LXC container, configures them fully
# Arguments:
# -c generate certificates, without this option create 'ssl' dir (in container directory) with ca, key+cert (signed by ca)
# -n container name
# --client_id and --client_secret are google developer's console generated credentials

tear_down_container() {
    local rv=$?
    case $rv in
        0|3)
        ;;
        *)
        echo "Fatal error, destroying container $CONTAINER_NAME"
        vagrant destroy
        ;;
    esac
    exit $rv
}
trap tear_down_container EXIT TERM INT

while [[ $# -gt 0 ]]; do
    arg="$1"
    case $arg in
        -r|--roots)
        ROOTS=true
        ;;
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
        --proxy-cert)
        SERVER_PROXY_CERT_FILE="$2"
        shift # past argument
        ;;
        --key)
        SERVER_KEY_FILE="$2"
        shift # past argument
        ;;
        --proxy-key)
        SERVER_PROXY_KEY_FILE="$2"
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
        --client_id)
        CLIENT_ID="$2"
        shift
        ;;
        --client_secret)
        CLIENT_SECRET="$2"
        shift
        ;;
        -u|--users)
        #comma separated alowed users list
        ALLOWED_USERS="$2"
        shift
        ;;
        -s|--stop)
        #comma separated alowed users list
        CONTAINER_STOP="$2"
        shift
        ;;
        *)
        # unknown option
        ;;
    esac
    shift # past argument or value
done

readonly AUTO_CERT_GENERATION=${GEN_CERT-false}
readonly USE_ROOTS=${ROOTS-false}
export readonly CONTAINER_NAME=${CN-ambassador}
export readonly CONTAINER_CERT_BASE=/etc/foreman/ssl
export readonly CONTAINER_CERT_DIR=$CONTAINER_CERT_BASE/certs
export readonly CONTAINER_PRIVATE_DIR=$CONTAINER_CERT_BASE/private
export readonly CONTAINER_USERNAME=root
export readonly CONTAINER_USER_HOME=/root # /home/$CONTAINER_USERNAME
readonly CONTAINER_OS=debian
readonly CONTAINER_OS_MAJOR=stretch
readonly CONTAINER_BACKING_STORE=best
readonly CONTAINER_STOP_AFTER=${CONTAINER_STOP-false}
export readonly USERS=${ALLOWED_USERS-"$USER"}

readonly setup_start_ts=$(date +%s.%N)

##### validate
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

if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "User: $CONTAINER_USERNAME, keypair doesn't exist, please generate it"
    exit 1
fi

export readonly CONTAINER_FQDN="$CONTAINER_NAME.$(dnsdomainname)"
readonly CONTAINER_ROOTFS=/var/lib/lxc/$CONTAINER_NAME/rootfs

##### initial

if [ "$AUTO_CERT_GENERATION" = true ]; then
    . util/sec/cert_functions
    SSL_BASE=/tmp/ssl
    SSL_CERT_DIR=$SSL_BASE/certs
    SSL_PRIVATE_DIR=$SSL_BASE/private
    #further ssl/ca-certificates installation doesn't clear /etc/ssl/private/certs contents
    echo "generating ca, certs: $SSL_BASE"
    touch $SSL_BASE/index.txt
    echo '01' > $SSL_BASE/serial
    echo '01' > $SSL_BASE/crlnumber

    CA_PK_FILE=$SSL_PRIVATE_DIR/ca.key.pem
    CA_CERT_FILE=$SSL_CERT_DIR/ca.cert.pem
    SERVER_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN.key
    SERVER_PROXY_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN-proxy.key
    SERVER_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN.pem
    SERVER_PROXY_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN-proxy.pem
    CRL_FILE=$SSL_BASE/crl.pem
    gen_rsa_key $CA_PK_FILE
    gen_x509_cert_self_signed $CA_PK_FILE $CA_CERT_FILE config/ssl/openssl-ca.cnf $SSL_BASE
    echo "ca generation done, generating server secrets"
    gen_crl_nonstd $CA_PK_FILE $CA_CERT_FILE $CRL_FILE config/ssl/openssl-ca.cnf $SSL_BASE
    gen_rsa_key $SERVER_KEY_FILE
    SERVER_FQDN=$CONTAINER_FQDN gen_csr $SERVER_KEY_FILE /tmp/$CONTAINER_FQDN.csr config/ssl/openssl-server.cnf $SSL_BASE
    echo "signing server's csr"
    gen_csr_sign /tmp/$CONTAINER_FQDN.csr $SERVER_CERT_FILE config/ssl/openssl-ca.cnf $SSL_BASE
    # key/cert for foreman-proxy as well
    gen_rsa_key $SERVER_PROXY_KEY_FILE
    SERVER_FQDN=$CONTAINER_FQDN-proxy gen_csr $SERVER_PROXY_KEY_FILE /tmp/$CONTAINER_FQDN-proxy.csr config/ssl/openssl-server.cnf $SSL_BASE
    echo "signing server's proxy csr"
    gen_csr_sign /tmp/$CONTAINER_FQDN-proxy.csr $SERVER_PROXY_CERT_FILE config/ssl/openssl-ca.cnf $SSL_BASE
fi

##### build container

. util/vm/lxc_functions #remove

vagrant up --provider=lxc

##### after completion
#reinstall known hosts
OIFS=$IFS
IFS=","
for u in $USERS; do
    ssh-keygen -f ~$u/.ssh/known_hosts -R $2
    chown $u.$u ~$u/.ssh/known_hosts
done
IFS=$OIFS

. util/core/text_functions

# prepare directories
mkdir -p $CONTAINER_ROOTFS/etc/salt/deploykeys/
mkdir -p $CONTAINER_ROOTFS/etc/salt/master.d/
mkdir -p $CONTAINER_ROOTFS/etc/salt/cloud.providers.d/
mkdir -p $CONTAINER_ROOTFS/etc/salt/cloud.profiles.d/
mkdir -p $CONTAINER_ROOTFS/etc/foreman-proxy/settings.d/
mkdir -p $CONTAINER_ROOTFS/etc/dnsmasq.d/
mkdir -p $CONTAINER_ROOTFS/srv/salt_ext/
mkdir -p $CONTAINER_ROOTFS/var/lib/tftpboot/
mkdir -p $CONTAINER_ROOTFS/etc/apache2/sites-available/

AMBASSADOR_CA=$CONTAINER_CERT_DIR/$(basename $CA_CERT_FILE)
AMBASSADOR_CRL=$CONTAINER_CERT_BASE/$(basename $CRL_FILE)
AMBASSADOR_KEY=$CONTAINER_PRIVATE_DIR/$(basename $SERVER_KEY_FILE)
AMBASSADOR_PROXY_KEY=$CONTAINER_PRIVATE_DIR/$(basename $SERVER_PROXY_KEY_FILE)
AMBASSADOR_CERT=$CONTAINER_CERT_DIR/$(basename $SERVER_CERT_FILE)
AMBASSADOR_PROXY_CERT=$CONTAINER_CERT_DIR/$(basename $SERVER_PROXY_CERT_FILE)
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

if ([ -n $CLIENT_ID ] && [ -n $CLIENT_SECRET ]); then
    AMBASSADOR_CLIENT_ID=$CLIENT_ID
    AMBASSADOR_CLIENT_SECRET=$CLIENT_SECRET
fi

#copy dependencies to container
cp -r envoy/extensions/pillar/ $CONTAINER_ROOTFS/srv/salt_ext/
cp -r config/bootloader/* $CONTAINER_ROOTFS/var/lib/tftpboot/
cp -r extensions/file_ext_authorize/ $CONTAINER_ROOTFS/opt/
cp config/file_ext_authorize.service $CONTAINER_ROOTFS/etc/systemd/system/

#fill templates and copy to container
if [ "$USE_ROOTS" = true ]; then
    #if using roots, copy envoy to container as well
    cp -r envoy/salt/ $CONTAINER_ROOTFS/srv/
    cp -r envoy/pillar/ $CONTAINER_ROOTFS/srv/
    cp -r envoy/reactor/ $CONTAINER_ROOTFS/srv/

    substenv_file AMBASSADOR config/ambassador_roots.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_roots.conf
else
    if ! ([ -z $DEPLOY_PUB_FILE ] || [ -z $DEPLOY_PRIV_FILE ]); then
        substenv_file AMBASSADOR config/ambassador_gitfs_deploykeys.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_gitfs_deploykeys.conf
    fi
    substenv_file AMBASSADOR config/ambassador_gitfs.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_gitfs.conf
fi
substenv_file AMBASSADOR config/ambassador_common.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_common.conf
substenv_file AMBASSADOR config/ambassador_ext_pillar.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_ext_pillar.conf
substenv_file AMBASSADOR config/ambassador_salt_foreman.conf > $CONTAINER_ROOTFS/etc/salt/master.d/ambassador_salt_foreman.conf
substenv_file AMBASSADOR config/reactor.conf > $CONTAINER_ROOTFS/etc/salt/master.d/reactor.conf
substenv_file AMBASSADOR config/foreman.yaml > $CONTAINER_ROOTFS/etc/salt/foreman.yaml
substenv_file AMBASSADOR config/salt.yml > $CONTAINER_ROOTFS/etc/foreman-proxy/settings.d/salt.yml
substenv_file AMBASSADOR config/proxydhcp.conf > $CONTAINER_ROOTFS/etc/dnsmasq.d/proxydhcp.conf
substenv_file AMBASSADOR config/file_ext_authorize.conf > $CONTAINER_ROOTFS/opt/file_ext_authorize/file_ext_authorize.conf
#apache2 during installation removes contents of /etc/apache2/sites-available/, storing in tmp
substenv_file AMBASSADOR config/apache2/30-saltfs.conf > $CONTAINER_ROOTFS/var/tmp/30-saltfs.conf

#todo use /etc/ssl dir? ubuntu user add to ssl-cert group ?
#run container
echo "starting: $CONTAINER_NAME"
# -f (for lxc-start) not needed as during creation the option got persisted
start_container_waiting_for_network $CONTAINER_NAME
echo "container running"

#sometimes sshd need more time
sleep 5

readonly CONTAINER_IP=$(lxc-info -n $CONTAINER_NAME -i | cut -d: -f2 | sed -e 's/ //g')

if [ -z "$CONTAINER_IP" ]; then
    echo "cannot resolve IP (domain = $CONTAINER_FQDN, IP = $CONTAINER_IP) for container, exiting"
    exit 1
fi
#this node (running setup.sh script) doesn't add ambassador to known hosts
#as doing so will cause repeating "Host Verification Failed"
if [ "$CONTAINER_USERNAME" = "root" ]; then
    ENTRY_CMD='bash -s'
else
    ENTRY_CMD='sudo -E bash -s'
fi
echo "running 'run' script inside container (IP = $CONTAINER_IP, DOMAIN=$CONTAINER_FQDN)"

readonly run_start_ts=$(date +%s.%N)

ssh $CONTAINER_USERNAME@$CONTAINER_IP -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" \
CIP=$CONTAINER_IP CID=$CONTAINER_FQDN CERT_BASEDIR=$CONTAINER_CERT_BASE CA=$AMBASSADOR_CA CRL=$AMBASSADOR_CRL KEY=$AMBASSADOR_KEY CERT=$AMBASSADOR_CERT \
PROXY_KEY=$AMBASSADOR_KEY PROXY_CERT=$AMBASSADOR_CERT \
$ENTRY_CMD < ./run.sh > $CONTAINER_NAME.log 2>&1 &
echo "script running in background, waiting for: $!"
wait $!
retval=$?
echo "stopping container"

if [ "$CONTAINER_STOP_AFTER" = true ]; then
    stop_container $CONTAINER_NAME
fi

readonly run_stop_ts=$(date +%s.%N)

readonly container_prep_time=$(echo "$run_start_ts - $setup_start_ts" | bc)
readonly run_time=$(echo "$run_stop_ts - $run_start_ts" | bc)
readonly total_time=$(echo "$run_stop_ts - $setup_start_ts" | bc)

echo "Container preparation time: ${container_prep_time}[s]"
echo "Installation time: ${run_time}[s]"
echo "Total time: ${total_time}[s] "

if [ $retval -ne 0 ]; then
    echo "error running run.sh script inside of container: $retval, check: $CONTAINER_NAME.log file"
    exit 1
else
    echo "success"
fi
