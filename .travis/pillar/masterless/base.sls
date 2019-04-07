hosts:
  1.2.3.4 : [ coolname ]
  192.168.1.1 : [ gw, mygw ]

locale:
  locales:
    - en_US.UTF-8
    - pl_PL.UTF-8

mail:
  configs:
    - location: "/etc/exim4/update-exim4.conf.conf"
      source: "salt://mail/templates/update-exim4.conf.conf"
      user: 'root'
      group: 'root'
      mode: '644'
      settings:
        dc_eximconfig_configtype: 'smarthost'
        dc_other_hostnames: ''
        dc_local_interfaces: '127.0.0.1'
        dc_readhost: ''
        dc_relay_domains: ''
        dc_minimaldns: 'false'
        dc_relay_nets: ''
        dc_smarthost: 'smtp.gmail.com::587'
        CFILEMODE: '644'
        dc_use_split_config: 'true'
        dc_hide_mailname: 'false'
        dc_mailname_in_oh: 'true'
        dc_localdelivery: 'mail_spool'
        MAIN_TLS_ENABLE: 1
        disable_ipv6: 'true'
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
