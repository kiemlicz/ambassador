{% set os = salt['grains.get']('lsb_distrib_id') %}
{% set dist_codename = salt['grains.get']('lsb_distrib_codename') %}
repositories:
  {{ salt['grains.filter_by']({
    'Debian': {
      'sources_list_location': '/etc/apt/sources.list',
      'list':[],
      'preferences': [],
    },
    'RedHat': {
      'list': []
    },
  }, merge=salt['grains.filter_by']({
    'buster': {
      'list': [{
                 'file': '/etc/apt/sources.list.d/stable.list',
                 'names': [
                    "deb http://ftp.pl.debian.org/debian stable contrib main non-free",
                    "deb-src http://ftp.pl.debian.org/debian stable contrib main non-free"
                 ]
               },{
                 'file': '/etc/apt/sources.list.d/testing.list',
                 'names': [
                    "deb http://ftp.pl.debian.org/debian testing contrib main non-free",
                    "deb-src http://ftp.pl.debian.org/debian testing contrib main non-free"
                 ]
               },{
                  'file': '/etc/apt/sources.list.d/backports.list',
                  'names': [
                     "deb http://ftp.debian.org/debian buster-backports contrib main non-free",
                  ]
               },{
                   'file': '/etc/apt/sources.list.d/chrome.list',
                   'names': [
                      "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"
                   ],
                   'key_url': "https://dl.google.com/linux/linux_signing_key.pub",
               }],
      'preferences': [{
                        'file': '/etc/apt/preferences.d/stable.pref',
                        'pin': 'release a=stable',
                        'priority': '900'
                      },{
                        'file': '/etc/apt/preferences.d/testing.pref',
                        'pin': 'release a=testing',
                        'priority': '500'
                      },{
                        'file': '/etc/apt/preferences.d/backports.pref',
                        'pin': 'release o=Debian Backports',
                        'priority': '800'
                      }]
    },

  }, grain='oscodename'))|tojson }}
---
repositories:
  list:
    - names:
       - deb http://repo entry
       - deb-src repo entry
      file: /etc/apt/sources.list.d/somerepo.list
    - names:
       - other rpeo
      file: /etc/apt/soures.list.d/somefile.list
      key_url: http://key.com
  preferences:
    - file: /etc/apt/preferences.d/experimental.pref
      pin: 'release a=experimental'
      priority: '1'
