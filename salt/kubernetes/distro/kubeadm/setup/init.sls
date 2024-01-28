{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}
{%- set masters = kubernetes.nodes.masters %}

{%- if kubernetes.master.reset %}
kubeadm_master_reset:
  cmd.run:
    - name: "echo y | kubeadm reset"
    - require:
        - pkg: kubeadm
    - require_in:
        - sls: kubernetes.distro.kubeadm
{%- endif -%}

{%- if grains['id'] == masters|first %}
include:
- .first
{%- else %}
include:
- .other
{%- endif %}

{%- if not kubernetes.master.isolate %}
allow_schedule_on_master:
  cmd.script:
    - name: untaint.sh {{ grains['id'] }}
    - source: salt://kubernetes/untaint.sh
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
        - sls: kubernetes.distro.{{ kubernetes.distro }}
# todo else -> taint the node
{%- endif %}

{%- if masters|length > 1 %}
propagate_cert_key:
  module.run:
    - mine.send:
        - kubernetes_cert_key
        - mine_function: grains.get
        - "kubernetes:master:certificate_key"
    - require:
      - sls: kubernetes.distro.{{ kubernetes.distro }}
propagate_ip:
  module.run:
    - mine.send:
        - kubernetes_master_ip
        - mine_function: network.ip_addrs
        - cidr: {{ kubernetes_network.nodes.master_vip }}
    - require:
      - sls: kubernetes.distro.{{ kubernetes.distro }}
{%- else %}
propagate_ip:
  module.run:
    - mine.send:
        - kubernetes_master_ip
        - mine_function: network.ip_addrs
        - cidr: {{ kubernetes_network.nodes.cidr }}
    - require:
      - sls: kubernetes.distro.{{ kubernetes.distro }}
{%- endif %}

#todo the cmd.run should be wrapped with script and return stateful data
