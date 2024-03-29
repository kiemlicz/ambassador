# Ambassador
[![Build status](https://travis-ci.org/kiemlicz/ambassador.svg?branch=master)](https://travis-ci.org/kiemlicz/ambassador)

Automated netboot&provisioning server, [Foreman](https://www.theforeman.org/) and [Salt](https://www.theforeman.org/) based.

## Rationale
Any setup takes time, practically it is never one-time action.  
Maintaining multi-node environments is cumbersome (configuration synchronization, duplicated installation process).
Sometimes it would also be useful to keep your favourite os hacks/tips/tricks in structured manner (like in some configuration management solution)
Moreover updates sometimes break, anything breaks at some point - then it _may be_ better to wipe everything/some part out
and start over. Unfortunately as some setup work had already been done such solution may be too radical.  

Setup any environment: dev, prod, work, home using Salt and PXE booting (the Foreman's).

Will aim to be both Linux&Windows friendly.

# Setup
As the best way of documenting things is writing automation scripts, this automation server's installation process is also automated.  
The "installation" process ends up with LXC container containing foreman&salt fully setup and configured.  
Simply follow:  
1. `git clone https://github.com/kiemlicz/ambassador.git`
2. Optionally provide `ambassador-installer.override.conf` to override any Salt masterless settings, e.g. add your own pillar:
```
ext_pillar:
  - git:
    - branch git@bitbucket.org:someone/pillar_repo.git:
      - root: pillar
      - env: base
```  
3. `sudo apt install lxc bridge-utils debootstrap python3-lxc`
4. `sudo SHELL=/bin/bash python3 installer/install.py --to lxc --name ambassador --ifc [ifc] [--kdbx the.db.kdbx] [--kdbx-pass thepassword] [--kdbx-key the.key] [--secrets https://secrets.server.com/path]`

Since foreman still doesn't support 'dockerized' deployment (cannot specify plugins for Foreman Docker images, no official foreman-proxy image).  
The provided `docker-compose.yml` can be used only to setup external DB or any other services. Use `docker-compose.override.yml` for any overrides:
```
version: '3'

services:
  db:
    environment:
      - POSTGRES_PASSWORD=realforemanpassword
    volumes:
      - db:/var/lib/postgresql/data

volumes:
  db:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /tmp/foreman
```

# Documentation
Foreman&Salt workflow is best depicted using this (Foreman's) diagram:
![](https://theforeman.org/static/images/diagrams/foreman_workflow_final.jpg)

For State Tree and custom extensions documentation, find the [State's Tree README.md](salt/README.md)

# Known problems
Provisioning of OSes involves many technologies and tools, it is very likely that something may not always works "as expected"
1. Many BIOS/UEFI TFTP clients are of very low quality and fail on option negotiation. Thus it may be needed to disable negotiation for 
 some options like _blksize_. Example for _tftp-hpa_ server: _/etc/default/tftpd-hpa_ append:  
 `TFTP_OPTIONS="--secure --refuse blksize"`

# Links&References
#### Tech stack manuals
* https://theforeman.org/manuals/
* https://docs.saltstack.com/en/latest/

#### Syslinux loaders
* https://www.kernel.org/pub/linux/utils/boot/syslinux/Testing/6.04/ (latest stable totally doesn't work for UEFI)

#### Debian netboot images
* https://www.debian.org/distrib/netinst#netboot

#### Debian preseeding
* https://wiki.debian.org/DebianInstaller/Preseed
* https://www.debian.org/releases/stable/amd64/ch05s03.html.en

#### General
1. https://wiki.debian.org/PXEBootInstall
