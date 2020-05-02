lxc:
  containers:
    keepalived:
      running: True
      template: debian
      network_profile:
        eth0:
          link: br0
          type: veth
          flags: up
      options:
        release: buster
        arch: amd64
#      config:
