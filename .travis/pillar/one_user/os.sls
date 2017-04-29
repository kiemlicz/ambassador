repositories:
  {{ salt['grains.filter_by']({
      'default': {
          'sources_list_location': '/etc/apt/sources.list',
          'preferences_template' : 'salt://repositories/template.pref',
          'list':[],
          'preferences': [],
      },
  }, merge=salt['grains.filter_by']({
      'stretch': {
          'list': [{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ unstable main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ unstable main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/unstable.list'
          },{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ experimental main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ experimental main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/experimental.list'
          },{
              'names': [
                  "deb http://dl.google.com/linux/chrome/deb/ stable main"
              ],
              'file': '/etc/apt/sources.list.d/google-chrome.list',
              'key_url': 'https://dl.google.com/linux/linux_signing_key.pub'
          }],
          'preferences': [{
              'file': '/etc/apt/preferences.d/experimental.pref',
              'pin': 'release a=experimental',
              'priority': '1'
          }]
      },
      'jessie': {
          'list': [{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ experimental main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ experimental main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/experimental.list'
          },{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ unstable main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ unstable main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/unstable.list'
          },{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ testing main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ testing main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/testing.list'
          },{
              'names': [
                  "deb http://ftp.pl.debian.org/debian/ stable main contrib non-free",
                  "deb-src http://ftp.pl.debian.org/debian/ stable main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/stable.list'
          },{
              'names': [
                  "deb http://security.debian.org/ stable/updates main contrib non-free",
                  "deb http://security.debian.org/ testing/updates main contrib non-free"
              ],
              'file': '/etc/apt/sources.list.d/security.list'
          }, {
              'names': [
                  "deb http://dl.google.com/linux/chrome/deb/ stable main"
              ],
              'file': '/etc/apt/sources.list.d/google-chrome.list',
              'key_url': 'https://dl.google.com/linux/linux_signing_key.pub'
          }],
          'preferences': [{
              'file': '/etc/apt/preferences.d/experimental.pref',
              'pin': 'release a=experimental',
              'priority': '1'
          },{
              'file': '/etc/apt/preferences.d/unstable.pref',
              'pin': 'release a=unstable',
              'priority': '50'
          },{
              'file': '/etc/apt/preferences.d/testing.pref',
              'pin': 'release a=testing',
              'priority': '750'
          },{
              'file': '/etc/apt/preferences.d/stable.pref',
              'pin': 'release a=stable',
              'priority': '990'
          },{
              'file': '/etc/apt/preferences.d/security.pref',
              'pin': 'release l=Debian-Security',
              'priority': '1000'
          }]
      },
  }, grain='oscodename')) }}

pkgs:
  names:
    {{ salt['grains.filter_by']({
         'default': ["aptitude", "apt-transport-https", "apt-listbugs", "apt-listchanges",
           "nano", "tmux", "tmuxinator", "vim", "sudo", "man", "rsync", "mc",
           "openssh-server", "openssh-client", "openvpn",
           "build-essential", "git", "zsh", "curl", "ethtool", "lm-sensors", "hddtemp", "hdparm", "ntp", "python-pip", "silversearcher-ag",
           "kde-standard", "xterm", "yakuake", "google-chrome-stable", "firefox"],
         'Windows': ["openvpn", "git", "wireshark", "keepass-2x"]
       }, merge=salt['grains.filter_by']({

         }, grain='oscodename')) }}

hosts:
  1.2.3.4 : [ coolname ]
  192.168.1.1 : [ gw, mygw]

mounts:
  - dev: /dev/sda1
    target: /mnt/hdd1/main
    file_type: ext4
    options: [user]
  - dev: /dev/sda2
    target: /mnt/hdd1/var
    file_type: ext4
    options: [user]
  - dev: /dev/sdb1
    target: /mnt/win_c
    file_type: ntfs-3g
    options: [user, rw, noauto, suid]
  - dev: /dev/sdd1
    target: /mnt/win_d
    file_type: ntfs
    options: [user, rw, noauto, suid]

locale:
  locales:
    - en_US.UTF-8
    - pl_PL.UTF-8
