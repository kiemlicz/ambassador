{% set default_pkgs = salt['grains.filter_by']({
      'default': {
         'os_packages': ["cron", "vim", "sudo", "insserv", "git", "zsh", "curl", "ca-certificates", "gnupg2", "python3-pip", "fonts-powerline"],
         'post_install': ['echo "command3"', 'echo "command4"', 'echo "command5"'],
      },

    },
    merge=salt['grains.filter_by']({
      'bionic': {
        'os_packages': ["cron", "vim", "sudo", "man-db", "rsync", "zsh", "git", "curl", "ntp",  "ca-certificates", "gnupg2", "python3-pip", "vim-gtk3", "fonts-powerline"],
      },
      'buster': {
        'os_packages': ["cron", "vim", "sudo", "insserv", "git", "zsh", "curl", "ca-certificates", "gnupg2", "python3-pip", "fonts-powerline", "initscripts"],
      },
      'bullseye': {
        'os_packages': ["cron", "vim", "sudo", "insserv", "git", "zsh", "curl", "ca-certificates", "gnupg2", "python3-pip", "fonts-powerline", "initscripts"],
      }
    }, grain='oscodename')) %}
pkgs:
  dist_upgrade: True
  unsafe_pip: True  # because we perform pip3 install --upgrade pip
  os_packages: {{ default_pkgs.os_packages | tojson }}
  pip3_packages:
#    - pip==20.3.3 # handled via unsafe_pip or outside the salt run
    - gdrive==0.0.9
    - google-auth-oauthlib~=0.5.1
    - powerline-status
  post_install:
    - "echo 'test'"
#  scripts:
#    - source: http://example.com/somescript.sh
#      args: "-a -b -c"
{% if grains['os'] == 'Debian' %}
  fromrepo:
      - from: buster-backports
        pkgs:
          - zsh
{% endif %}
  purged:
    - xserver-xorg-video-intel
