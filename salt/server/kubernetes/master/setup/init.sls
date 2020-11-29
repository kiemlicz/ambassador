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
        - cmd: kubeadm_init
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
        - cmd: kubeadm_init
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
      - cmd: kubeadm_init
propagate_ip:
  module.run:
    - mine.send:
        - kubernetes_master_ip
        - mine_function: network.ip_addrs
        - cidr: {{ kubernetes_network.nodes.master_vip }}
    - require:
      - cmd: kubeadm_init
{%- else %}
propagate_ip:
  module.run:
    - mine.send:
        - kubernetes_master_ip
        - mine_function: network.ip_addrs
        - cidr: {{ kubernetes_network.nodes.cidr }}
    - require:
      - cmd: kubeadm_init
{%- endif %}

ensure_token:
  module.run:
    - kubeadm.token_create: []
    - unless:
      - fun: kubeadm.token_list    
    - require:
      - cmd: kubeadm_init
propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: kubeadm.token_list
    - require:
      - module: ensure_token

propagate_hash:
  module.run:
    - mine.send:
        - kubernetes_hash
        - mine_function: cmd.run
        - "openssl x509 -pubkey -in {{ kubernetes.master.pki.dir }}/{{ kubernetes.master.ca.pub }} | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
        - python_shell: True
    - require:
      - cmd: kubeadm_init


#todo the cmd.run should be wrapped with script and return stateful data
