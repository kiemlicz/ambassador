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
