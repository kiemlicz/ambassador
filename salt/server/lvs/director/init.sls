{%- from "lvs/map.jinja" import lvs with context %}

lvs_director:
  pkg.latest:
    - name: {{ lvs.pkg_name }}
{%- if not salt.condition.container() %}
  kmod.present:
    - name: {{ lvs.module }}
    - persist: {{ lvs.persist_module }}
    - require:
      - pkg: {{ lvs.pkg_name }}
{%- endif %}
# todo assert this is needed

lvs_director_ip_forward:
  sysctl.present:
    - name: "net.ipv4.ip_forward"
    - value: 1
    - require:
      - kmod: {{ lvs.module }}

# http://www.austintek.com/LVS/LVS-HOWTO/HOWTO/LVS-HOWTO.LVS-DR.html#set_rp_filter
lvs_director_rp_filter:
  sysctl.present:
    - name: "net.ipv4.conf.all.rp_filter"
    - value: 0
    - require:
      - kmod: {{ lvs.module }}
