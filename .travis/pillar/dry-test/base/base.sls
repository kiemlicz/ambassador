hosts:
  1.2.3.4 : [ coolname ]
  192.168.1.1 : [ gw, mygw ]

locale:
  locales:
    - en_US.UTF-8
    - pl_PL.UTF-8

mail:
  configs:
    - location: "/etc/exim4/passwd"
      source: "salt://mail/templates/passwd"
      user: 'root'
      group: 'Debian-exim'
      mode: '640'
      settings:
        "username@domain.com": "uberpassword"
    - location: "/etc/email-addresses"
      source: "salt://mail/templates/email-addresses"
      user: 'root'
      group: 'root'
      mode: '644'
      settings:
        "username": "username@domain.com"
        "username@localhost": "username@domain.com"
