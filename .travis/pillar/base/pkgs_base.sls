{% set default_pkgs = salt['grains.filter_by']({
      'default': {
         'os_packages': ["cron", "vim", "sudo", "man-db", "insserv", "git", "zsh", "curl", "ca-certificates", "gnupg2"],
         'post_install': ['echo "command3"', 'echo "command4"', 'echo "command5"'],
      },
      'Windows': {
         'os_packages': ["openvpn", "git", "wireshark", "keepass-2x"]
       }
    },
    merge=salt['grains.filter_by']({
      'stretch': {
        'os_packages': ["cron", "vim", "sudo", "man-db", "rsync", "insserv", "git", "zsh", "curl", "ntp",  "ca-certificates", "gnupg2"],
      },
      'bionic': {
        'os_packages': ["vim", "sudo", "man-db", "rsync", "git", "zsh", "curl", "ntp",  "ca-certificates", "gnupg2"],
      }
    }, grain='oscodename')) %}

pkgs:
  {{ salt['grains.filter_by']({
            'somehost': {
              'os_packages': default_pkgs.os_packages + ["firmware-iwlwifi"]
              },
            }, grain='host', merge=default_pkgs) }}
