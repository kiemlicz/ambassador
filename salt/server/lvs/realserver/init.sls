{% from "lvs/map.jinja" import lvs with context %}

lvs_read_server_lo_rp_filter:
  sysctl.present:
  - name: net.ipv4.conf.lo.rp_filter
  - value: 2

lvs_real_server_lo_arp_ignore:
  sysctl.present:
  - name: net.ipv4.conf.lo.arp_ignore
  - value: 1

lvs_real_server_lo_arp_announce:
  sysctl.present:
  - name: net.ipv4.conf.lo.arp_announce
  - value: 2

# not setting VIP on the loopback interface here
# because the only reliable way of doing that is via reboot which breaks the highstate
# the VIP must be set via os.network beforehand
