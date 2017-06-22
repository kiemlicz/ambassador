# Ambassador
[![Build status](https://travis-ci.org/kiemlicz/ambassador.svg?branch=master)](https://travis-ci.org/kiemlicz/ambassador)

Automated netboot&provisioning server

## Rationale
Any setup takes time, practically it is never one-time action.  
Updates break sometimes, anything breaks at some point - sometimes it's better to wipe everything/some part out
and start over.  
Unfortunately as some setup work had already been done such solution may not be sensible.  
Maintaining multi-node environments is cumbersome (configuration synchronization, duplicated installation process).
Sometimes it would also be useful to keep your favourite os hacks/tips/tricks in structured manner (like in some configuration management solution)

Setup (dev, prod, work, home) node using saltstack and PXE booting.

Will aim to be both Linux&Windows friendly.

# Setup

As the best way of documenting things is writing automation scripts, this automation server's installation process
is also automated.  
The "installation" process end up with LXC container containing foreman&salt fully setup and configured.  
Simply follow two steps:  
1. Clone this repo with submodules: `git submodule update --init` ([read more about submodules](https://github.com/kiemlicz/util/wiki/git))
2. `nohup sudo ./setup.sh -c -n ambassador [-r] [--deploy_priv id_rsa --deploy_pub id_rsa.pub] &`

# Workflow

Foreman&Salt workflow is best depicted using this (Foreman's) diagram:
![](https://theforeman.org/static/images/diagrams/foreman_workflow_final.jpg)

# Links&References
#### Tech stack manuals
* https://theforeman.org/manuals/
* https://docs.saltstack.com/en/latest/

#### Debian netboot images
* https://www.debian.org/distrib/netinst#netboot

#### Debian preseeding
* https://wiki.debian.org/DebianInstaller/Preseed
* https://www.debian.org/releases/stable/amd64/ch05s03.html.en

#### General
1. https://wiki.debian.org/PXEBootInstall
