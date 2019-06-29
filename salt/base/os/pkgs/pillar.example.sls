pkgs:
  dist_upgrade: True
  os_packages:
    - zsh
  versions:
    - "python-pip: 9.0.1-2.3"
  pip_packages:
    - pip_package
    - google-auth
  post_install:
    - some command
    - to be executed
  scripts:
    - source: http://example.com/somescript.sh
      args: "-a -b -c"
---
{% set default_pkgs = salt['grains.filter_by']({
      'default': {
         'os_packages': ["vim", "sudo", "man", "insserv", "git", "zsh", "curl", "ca-certificates", "gnupg2"],
         'sources': [{
             'keepassxc': "https://github.com/magkopian/keepassxc-debian/releases/download/2.3.3/keepassxc_2.3.3-1_amd64_stable_stretch.deb"
          }],
         'post_install': ['echo "command3"', 'echo "command4"', 'echo "command5"'],
      },
      'Windows': {
         'os_packages': ["openvpn", "git", "wireshark", "keepass-2x"]
       }
    },
    merge=salt['grains.filter_by']({
      'stretch': {
        'os_packages': ["vim", "sudo", "man", "rsync", "insserv", "git", "zsh", "curl", "ntp",  "ca-certificates", "gnupg2"],
        'pip_packages': ["pyasn1-modules"],
        'pip3_packages': ["kubernetes"]
      },
      'bionic': {
        'os_packages': ["vim", "sudo", "man", "rsync", "git", "zsh", "curl", "ntp",  "ca-certificates", "gnupg2"],
      }
    }, grain='oscodename')) %}

pkgs:
  {{ salt['grains.filter_by']({
            'somehost': {
              'os_packages': default_pkgs.os_packages + ["firmware-iwlwifi"]
              },
            }, grain='host', merge=default_pkgs) }}
