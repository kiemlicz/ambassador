#!/usr/bin/env bash

# Builds foreman + salt inside LXC container, configures them fully
# Arguments:
# -c generate certificates, without this option create 'ssl' dir (in container directory) with ca, key+cert (signed by ca)
# -n container name

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
        --pillar_priv)
        PILLAR_GPG_PRIV_FILE="$2"
        shift
        ;;
        --pillar_pub)
        PILLAR_GPG_PUB_FILE="$2"
        shift
        ;;
        --ambassador_kdbx)
        AMBASSADOR_KDBX="$2"
        shift
        ;;
        --ambassador_key)
        AMBASSADOR_KDBX_KEY="$2"
        shift
        ;;
        -u|--users)
        #comma separated alowed users list
        ALLOWED_USERS="$2"
        shift
        ;;
        -s|--stop)
        #stop container after finish
        CONTAINER_STOP="true"
        ;;
        -a|--auto_start)
        #add auto-start flag for container
        CONTAINER_AUTO_START="1"
        ;;
        *)
        # unknown option
        ;;
    esac
    shift # past argument or value
done

readonly setup_start_ts=$(date +%s.%N)

##### validate

if [[ $EUID -eq 0 ]]; then
   echo "Warning: script is running as root"
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

export readonly CONTAINER_NAME=${CN-ambassador}
export readonly CONTAINER_USERNAME=root
export readonly CONTAINER_USER_HOME=/root # /home/$CONTAINER_USERNAME
export readonly USERS=${ALLOWED_USERS-"$USER"}
export readonly AMBASSADOR_AUTO_START=${CONTAINER_AUTO_START-"0"}
export readonly CONTAINER_FQDN="$CONTAINER_NAME.$(dnsdomainname)"
export DEPLOY_PUB_FILE
export DEPLOY_PRIV_FILE
export PILLAR_GPG_PUB_FILE
export PILLAR_GPG_PRIV_FILE
export AMBASSADOR_KDBX
export AMBASSADOR_KDBX_KEY
readonly CONTAINER_STOP_AFTER=${CONTAINER_STOP-false}

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

echo "Container preparation time: ${container_prep_time}[s]"
echo "Installation time: ${run_time}[s]"
echo "Total time: ${total_time}[s] "
