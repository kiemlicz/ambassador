mail:
  configs:
    - location: "/etc/exim4/update-exim4.conf.conf"
      source: "salt://mail/templates/update-exim4.conf.conf"
    - location: "/etc/exim4/passwd"
      source: "salt://mail/templates/passwd"
      settings:
        "username@domain.com": "uberpassword"
    - location: "/etc/email-addresses"
      source: "salt://mail/templates/email-addresses"
      settings:
        "username": "username@domain.com"
        "username@localhost": "username@domain.com"
