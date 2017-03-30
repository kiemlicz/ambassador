#Basics
Automated netboot&provision server

##Rationale
Any setup takes time, practically it is never one-time action.  
Updates break sometimes, anything breaks at some point - sometimes it's better to wipe everything/some part out
and start over. Unfortunately as some work had already been done such solution may not be feasible.  
Maintaining multi-node environments is cumbersome (configuration synchronization, duplicated installation process)
Way of saving forgotten configuration tips&tricks for further re-use

Setup (dev, prod, work, home) node using saltstack and pxeboot.

Saltstack is not used for per user configuration management&synchronization, git is
(using this technique: https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo).
Configured node clones the git cfg repo and uses it as its own apps configuration

Linux&Windows friendly



#Links&References
Debian netboot images:
* https://www.debian.org/distrib/netinst#netboot

Debian preseeding:
* https://wiki.debian.org/DebianInstaller/Preseed
* https://www.debian.org/releases/stable/amd64/ch05s03.html.en

General: 
1. https://wiki.debian.org/PXEBootInstall