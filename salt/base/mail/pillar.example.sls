mail:
  configs:
    update-exim4.conf.conf:
      location: "/etc/exim4/update-exim4.conf.conf"
      source: "salt://mail/templates/update-exim4.conf.conf"
    passwd:
      location: "/etc/exim4/passwd"
      source: "salt://mail/templates/passwd"
      user: 'root'
      group: 'Debian-exim'
      mode: '640'
      settings:
        "username@domain.com": "uberpassword"
    email-addresses:
      location: "/etc/email-addresses"
      source: "salt://mail/templates/email-addresses"
      user: 'root'
      group: 'root'
      mode: '644'
      settings:
        "username": "username@domain.com"
        "username@localhost": "username@domain.com"

# if some files must not be present use:
# ...
# passwd: null
