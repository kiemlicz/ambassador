#!/usr/bin/env bash

#ensure that all mandatory components for LXC host are installed
#ensure network is setup - add default lxc settings
#ensure dns

#manual checks:
#if running in vm: check that NIC is in promisc mode
#In order to use containers inside of virtualbox with bridged connection, the vbox NIC must be configured to:
#0. VirtualBox extpack must be installed
#1. "Promiscuous Mode" set to "Allow All"
#2. (optional if previous is not sufficient) PCnet-FAST III
#LXC in Debian uses debootstrap, ensure that /usr/share/debootstrap/scripts/ contains desired distros
#Debian stable may contain old LXC version which may be unable to spin ubuntu, replace lxc-ubuntu template with sid's version

# for vbox as netboot client, create VM & set:
# network boot set as first
# hard disk as second
########################################

apt-get update
#ubuntu-archive-keyring for ubuntu archives creation
apt-get install lxc bridge-utils debootstrap vagrant vagrant-lxc python3-lxc python3-pip
pip3 install pyyaml pykeepass

#ubuntu-archive-keyring not working for yakkety (and up)
apt-get install ubuntu-archive-keyring

mv /etc/default/lxc-net /etc/default/lxc-net.$(date +%F-%T).old
cp requisites/lxc-net /etc/default/lxc-net

readonly DEFAULT_INTERFACE=$(ip route get 8.8.8.8 | head -n1 | cut -d' ' -f5)
mv /etc/network/interfaces /etc/network/interfaces.$(date +%F-%T).old
sed -e "s;%IFACE%;$DEFAULT_INTERFACE;g" requisites/interfaces > /etc/network/interfaces

sed -i '/^#net.ipv4.ip_forward/s/^#//' /etc/sysctl.conf
sysctl -p
#todo add check if the grub is installed
#todo ensure fqdn (add hosts entry)
sed -i '/^GRUB_CMDLINE_LINUX/s/"$/cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub2
lxc-checkconfig

# provide CONTAINER_FQDN
CONTAINER_FQDN=${1-ambassador}
# provide SSL_BASE
SSL_BASE=.target/etc/foreman/ssl
# generate certificates
. util/sec/cert_functions
mkdir -p .target/etc/foreman/ssl/private
mkdir -p .target/etc/foreman/ssl/certs

SSL_CERT_DIR=$SSL_BASE/certs
SSL_PRIVATE_DIR=$SSL_BASE/private
#further ssl/ca-certificates installation doesn't clear /etc/ssl/private/certs contents
echo "generating ca, certs: $SSL_BASE"
touch $SSL_BASE/index.txt
echo '01' > $SSL_BASE/serial
echo '01' > $SSL_BASE/crlnumber

export readonly CA_PK_FILE=$SSL_PRIVATE_DIR/ca.key.pem
export readonly CA_CERT_FILE=$SSL_CERT_DIR/ca.cert.pem
export readonly SERVER_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN.key
export readonly SERVER_PROXY_KEY_FILE=$SSL_PRIVATE_DIR/$CONTAINER_FQDN-proxy.key
export readonly SERVER_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN.pem
export readonly SERVER_PROXY_CERT_FILE=$SSL_CERT_DIR/$CONTAINER_FQDN-proxy.pem
export readonly CRL_FILE=$SSL_BASE/crl.pem
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