{% set default_pkgs = salt['grains.filter_by']({
      'default': {
         'os_packages': ["aptitude", "apt-transport-https", "apt-listbugs", "apt-listchanges", "unattended-upgrades",
                   "nano", "tmux", "tmuxinator", "vim", "sudo", "man-db", "rsync", "mc",
                   "openssh-server", "openssh-client", "openvpn", "insserv",
                   "build-essential", "git", "zsh", "curl", "ethtool", "ntp", "python3-pip",
                   "silversearcher-ag", "exuberant-ctags", "tig", "software-properties-common",
		           "ca-certificates", "gnupg2"],
         'post_install': ['echo "command3"', 'echo "command4"', 'echo "command5"'],
      },
      'Windows': {
         'os_packages': ["openvpn", "git", "wireshark", "keepass-2x"]
       }
    },
    merge=salt['grains.filter_by']({
      'stretch': {
        'os_packages': ["aptitude", "apt-transport-https", "apt-listbugs", "apt-listchanges", "unattended-upgrades",
                   "nano", "tmux", "tmuxinator", "vim", "sudo", "man-db", "rsync", "mc",
                   "openssh-server", "openssh-client", "openvpn", "insserv",
                   "build-essential", "git", "zsh", "curl", "ethtool", "ntp", "python3-pip",
                   "silversearcher-ag", "exuberant-ctags", "tig", "software-properties-common",
		           "ca-certificates", "gnupg2"],
      },
      'bionic': {
        'os_packages': ["aptitude", "apt-transport-https",
                   "nano", "tmux", "tmuxinator", "vim", "sudo", "man-db", "rsync", "mc",
                   "openssh-server", "openssh-client", "openvpn",
                   "build-essential", "git", "zsh", "curl", "ethtool", "ntp", "python3-pip",
                   "silversearcher-ag", "exuberant-ctags", "tig", "software-properties-common",
		           "ca-certificates", "gnupg2"],
      }
    }, grain='oscodename')) %}

pkgs:
  {{ salt['grains.filter_by']({
            'somehost': {
              'os_packages': default_pkgs.os_packages + ["firmware-iwlwifi"]
              },
            }, grain='host', merge=default_pkgs)|tojson }}
