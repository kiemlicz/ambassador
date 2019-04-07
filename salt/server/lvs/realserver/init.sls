#!jinja|stringpy

import json

{% from "keepalived/map.jinja" import keepalived with context %}


def run():
  keepalived = {{ keepalived|json }}
  state = {}
  virtual_addresses = {}

  for k, v in keepalived.get("virtual_servers", {}).items():
    vip = k.split(" ")[0]
    for rip in [e.split(" ")[0] for e in v.get("real_servers", {}).keys()]:
      if rip in {{ salt['network.ip_addrs']()|json }}:
        # speed up - filter out RIPs that don't belong to this minion
        virtual_addresses.setdefault(rip, []).append(vip)

  #state["lvs_read_server_default_rp_filter"] = {
  #    'sysctl.present': [
  #        { 'name': "net.ipv4.conf.default.rp_filter" },
  #        { 'value': "2" },
  #      ]
  #}

  state["lvs_read_server_lo_rp_filter"] = {
      'sysctl.present': [
          { 'name': "net.ipv4.conf.lo.rp_filter" },
          { 'value': "2" },
        ]
  }

  for rip, vips in virtual_addresses.items():
    state["lvs_real_server_ip_{}_arp_ignore".format(rip)] = {
        'sysctl.present': [
          { 'name': "net.ipv4.conf.lo.arp_ignore" },
          { 'value': "1" },
        ]
    }
    state["lvs_real_server_ip_{}_arp_announce".format(rip)] = {
        'sysctl.present': [
          { 'name': "net.ipv4.conf.lo.arp_announce" },
          { 'value': "2" },
        ]
    }
    for i in range(0, len(vips)):
      vip = vips[i]
      state["lvs_real_server_ip_{}_assign_vip_{}".format(rip, vip)] = {
        'network.managed': [
         { 'name': "lo:{}".format(i + 1) },
         { 'enabled': True },
         { 'type': "eth" },
         { 'ipaddr': vip },
         { 'netmask': "255.255.255.255" },
         { 'proto': "static" },
         { 'require': [
          { 'sysctl': "lvs_real_server_ip_{}_arp_ignore".format(rip) },
          { 'sysctl': "lvs_real_server_ip_{}_arp_announce".format(rip) },
#          { 'sysctl': "lvs_read_server_default_rp_filter" },
          { 'sysctl': "lvs_read_server_lo_rp_filter" }
         ]}
        ]
      }

  return state
