def _data(env):
    assertions = {
        'empty': ["sudo", "apt-transport-https", "man", "rsync", "git", "curl", "ntp", "zsh"],
        'one_user': ["aptitude", "apt-transport-https", "apt-listbugs", "apt-listchanges", "unattended-upgrades",
                     "nano", "tmux", "tmuxinator", "vim", "sudo", "man", "rsync", "mc",
                     "openssh-server", "openssh-client", "openvpn",
                     "build-essential", "git", "zsh", "curl", "ethtool", "lm-sensors", "hddtemp", "hdparm", "ntp", "python-pip",
                     "silversearcher-ag", "kde-standard", "xterm", "yakuake", "print-manager", "wireshark", "network-manager-openvpn",
                     "google-chrome-stable", "firefox", "exuberant-ctags", "tig", "libreoffice", "software-properties-common",
                     "ca-certificates", "gnupg2"]
    }
    return assertions[env]


def assert_pkgs(pkgs_list, pillarenv):
    expected = _data(pillarenv)
    return len(pkgs_list) == len(expected) and sorted(pkgs_list) == sorted(expected)
