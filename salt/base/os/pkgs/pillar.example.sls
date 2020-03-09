{% set default_pkgs = salt['grains.filter_by']({
      'default': {
         'os_packages': ["cron", "vim", "sudo", "insserv", "git", "curl", "ca-certificates", "gnupg2", "python3-pip", "fonts-powerline"],
         'post_install': ['echo "command3"', 'echo "command4"', 'echo "command5"'],
      },

    },
    merge=salt['grains.filter_by']({
      'bionic': {
        'os_packages': ["cron", "vim", "sudo", "man-db", "rsync", "zsh", "git", "curl", "ntp",  "ca-certificates", "gnupg2", "python3-pip", "vim-gtk3", "fonts-powerline"],
      }
    }, grain='oscodename')) %}
pkgs:
  dist_upgrade: True
  os_packages: {{ default_pkgs.os_packages | tojson }}
  versions:
    - "python-pip: 9.0.1-2.3"
  pip3_packages:
    - google-api-python-client
    - google-auth-httplib2
    - google-auth-oauthlib
    - powerline-status
  post_install:
    - "echo 'test'"
#  scripts:
#    - source: http://example.com/somescript.sh
#      args: "-a -b -c"
  fromrepo:
      - from: buster-backports
        pkgs:
          - zsh
  purged:
    - xserver-xorg-video-intel
