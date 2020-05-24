lxc:
  containers:
    keepalived-{{ grains['host'] }}:
      running: True
      network_profile:
        eth0:
          link: br0
          type: veth
          flags: up
      template: debian
      options:
        release: buster
        arch: amd64
      bootstrap_args: "-x python3"
#      config:
