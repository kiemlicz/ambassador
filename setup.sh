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
        --ssl-base)
        SSL_BASE="$2"
        shift # past argument
        ;;
        -n|--name)
        CN="$2"
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
export readonly TFTP_ROOT="/srv/tftp"

readonly setup_start_ts=$(date +%s.%N)

##### validate

if [[ $EUID -eq 0 ]]; then
   echo "Warning: script is running as root"
fi

if [ -z "$SSL_BASE" ]; then
    echo "Provide --ssl-base directory with all keys and certificates"
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

##### initial
export readonly CONTAINER_FQDN="$CONTAINER_NAME.$(dnsdomainname)"
readonly CONTAINER_ROOTFS=/var/lib/lxc/$CONTAINER_NAME/rootfs
# certificates and keys are expected to be found in following locations
SSL_CERT_DIR=$SSL_BASE/certs
SSL_PRIVATE_DIR=$SSL_BASE/private
#export readonly CA_PK_FILE=$SSL_PRIVATE_DIR/ca.key.pem
export readonly CA_CERT_FILE=$SSL_CERT_DIR/ca.cert.pem
export readonly SERVER_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN.key
export readonly SERVER_PROXY_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN-proxy.key
export readonly SERVER_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN.pem
export readonly SERVER_PROXY_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN-proxy.pem
export readonly CRL_FILE=$SSL_BASE/crl.pem

mkdir -p .target/etc/foreman/
cp -r $SSL_BASE .target/etc/foreman/

##### build container

readonly run_start_ts=$(date +%s.%N)

vagrant up --provider=lxc

##### after completion
#reinstall known hosts
OIFS=$IFS
IFS=","
for u in $USERS; do
    user_homedir=$(eval echo ~"$u")
    ssh-keygen -f $user_homedir/.ssh/known_hosts -R $CONTAINER_FQDN
    chown $u.$u $user_homedir/.ssh/known_hosts
done
IFS=$OIFS

if [ "$CONTAINER_STOP_AFTER" = true ]; then
    stop_container $CONTAINER_NAME
fi

readonly run_stop_ts=$(date +%s.%N)

readonly container_prep_time=$(echo "$run_start_ts - $setup_start_ts" | bc)
readonly run_time=$(echo "$run_stop_ts - $run_start_ts" | bc)
readonly total_time=$(echo "$run_stop_ts - $setup_start_ts" | bc)

#cleanup
rm -rf ./.target

echo "Container preparation time: ${container_prep_time}[s]"
echo "Installation time: ${run_time}[s]"
echo "Total time: ${total_time}[s] "
