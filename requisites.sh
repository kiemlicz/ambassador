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
apt-get install lxc bridge-utils debootstrap

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
