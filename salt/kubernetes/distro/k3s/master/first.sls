{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}
{%- from "kubernetes/distro/k3s/_install.macros.jinja" import k3s_install with context %}
{%- set masters = k3s.nodes.masters %}
{%- set ip = salt.filters.ips_in_subnet(grains['ipv4'], cidr=k3s.config.kubevip.cidr)|first %}

kube_vip_rbac:
  file.managed:
    - name: {{ k3s.config.statics }}/kube-vip-rbac.yaml
    - source: salt://kubernetes/distro/k3s/kubevip/rbac.yaml
    - makedirs: True
    - require:
      - file: k3s_config

kube_vip_ds:
  file.managed:
    - name: {{ k3s.config.statics }}/kube-vip.yaml
    - source: salt://kubernetes/distro/k3s/kubevip/ds.yaml
    - makedirs: True
    - template: jinja
    - context:
        vip: {{ k3s.config.kubevip.vip }}
        vip_interface: {{ k3s.config.kubevip.vip_interface }}
        bgp_peers: {{ k3s.config.kubevip.bgp_peers }}
        router_id: {{ ip }}
    - require:
      - file: kube_vip_rbac
    - require_in:
      - cmd: k3s
