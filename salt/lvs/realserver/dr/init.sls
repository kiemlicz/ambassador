{% from "lvs/map.jinja" import lvs with context %}

lvs_read_server_{{ lvs.realservers.ifc }}_rp_filter:
  sysctl.present:
  - name: net.ipv4.conf.{{ lvs.realservers.ifc }}.rp_filter
  - value: 2

lvs_real_server_{{ lvs.realservers.ifc }}_arp_ignore:
  sysctl.present:
  - name: net.ipv4.conf.{{ lvs.realservers.ifc }}.arp_ignore
  - value: 1

lvs_real_server_{{ lvs.realservers.ifc }}_arp_announce:
  sysctl.present:
  - name: net.ipv4.conf.{{ lvs.realservers.ifc }}.arp_announce
  - value: 2