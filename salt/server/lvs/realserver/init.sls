#!py

import json
import logging

log = logging.getLogger(__name__)


def run():
  virtual_servers = __salt__['pillar.get']("keepalived:virtual_servers", {})
  state = {}
  virtual_addresses = {}
  vips = []

  def restart_interface(req, ifc="lo"):
    return {
      'lvs_real_server_interface_{}_down'.format(ifc): {
        'module.run': [
          { 'name': 'ip.down' },
          { 'iface': ifc },
          { 'iface_type': "eth" },
          { 'onchanges': [
            {'network': ifc}
          ] },
        ]
      },
      'lvs_real_server_interface_{}_up'.format(ifc): {
        'module.run': [
          { 'name': 'ip.up' },
          { 'iface': ifc },
          { 'iface_type': "eth" },
          { 'onchanges': [
            {'module': 'lvs_real_server_interface_{}_down'.format(ifc)}
          ] },
        ]
      },
    }

  for k, v in virtual_servers.items():
    vip = k.split(" ")[0]
    vips.append(vip)
    for rip in [e.split(" ")[0] for e in v.get("real_servers", {}).keys()]:
      if rip in __salt__['network.ip_addrs']():
        # speed up - filter out RIPs that don't belong to this minion
        virtual_addresses.setdefault(rip, []).append(vip)

  #state["lvs_real_server_default_rp_filter"] = {
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

  # todo find vip's interface, iterate over VIPs
  state["lvs_real_server_lo_arp_ignore"] = {
      'sysctl.present': [
        { 'name': "net.ipv4.conf.lo.arp_ignore" },
        { 'value': "1" },
      ]
  }
  state["lvs_real_server_lo_arp_announce"] = {
      'sysctl.present': [
        { 'name': "net.ipv4.conf.lo.arp_announce" },
        { 'value': "2" },
      ]
  }

  # fixme ip address is not applied, manual restart fixes this... debug this issue
  for vip in vips:
    state["lvs_real_server_ip_{}_assign_vip_{}".format(rip, vip)] = {
      'network.managed': [
       { 'name': "lo" },
       { 'enabled': True },
       { 'type': "eth" },
       { 'up_cmds': ["ip addr add {}/32 dev $IFACE label $IFACE:0".format(vip)] },
       { 'down_cmds': ["ip addr del {}/32 dev $IFACE label $IFACE:0".format(vip)] },
       { 'proto': "static" },
       { 'require': [
        { 'sysctl': "lvs_real_server_lo_arp_ignore" },
        { 'sysctl': "lvs_real_server_lo_arp_announce" },
#        { 'sysctl': "lvs_read_server_default_rp_filter" },
        { 'sysctl': "lvs_read_server_lo_rp_filter" }
       ]}
      ]
    }
    #state.update(restart_interface("lvs_real_server_ip_{}_assign_vip_{}".format(rip, vip)))

  return state
