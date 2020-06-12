{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context %}

{%- set masters = kubernetes.nodes.masters %}
{%- if not masters %}
kubernetes-no-masters:
    test.fail_without_changes:
        - name: Kubernetes master nodes not specifed
{%- else %}
{%- if kubernetes.master.reset %}
kubeadm_master_reset:
  cmd.run:
    - name: "echo y | kubeadm reset"
    - require:
        - pkg: kubeadm
    - require_in:
        - cmd: kubeadm_init
{% endif %}

{% if grains['id'] == masters|first and masters|length > 1 %}

kubeadm_multi_master_config:
  file.managed:
    - name: {{ kubernetes.master.multi_master_config_location }}
    - source: {{ kubernetes.master.multi_master_config }}
    - makedirs: True
    - template: jinja
    - user: {{ kubernetes.user }}
    - require_in:
      - cmd: kubeadm_init
{% set cmd = "kubeadm init --config="~ kubernetes.master.multi_master_config_location ~ "--upload-certs" %}

{% elif masters|length > 1 %}

{% set tokens = salt['mine.get'](masters|join(","), "kubernetes_token", tgt_type="list") %}
{% set ips = salt['mine.get'](masters|join(","), "kubernetes_master_ip", tgt_type="list") %}
{% set hashes = salt['mine.get'](masters|join(","), "kubernetes_hash", tgt_type="list") %}
{% set cert_key = salt['mine.get'](masters|join(","), "kubernetes_cert_key", tgt_type="list") %}
{% set main_master_id = ips.keys()|sort|first %}
{% set cmd = "kubeadm join --token " ~ tokens[main_master_id]['stdout'] ~ " " ~ ips[main_master_id][0] ~ ":" ~ kubernetes_network.nodes.port ~ "--discovery-token-ca-cert-hash sha256:" ~ hashes[main_master_id] ~ "--control-plane --certificate-key " ~ cert_key[main_master_id] %}

{% else %}

{% set cmd = "kubeadm init --pod-network-cidr " ~ kubernetes_network.network.cidr %}

{% endif %}

kubeadm_init:
  cmd.run:
    - name: {{ cmd }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.network.{{ kubernetes_network.network.provider }}
    - unless: test -f /etc/kubernetes/admin.conf

{% if not kubernetes.master.isolate %}
allow_schedule_on_master:
  cmd.script:
    - name: untaint.sh {{ grains['id'] }}
    - source: salt://kubernetes/untaint.sh
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
        - cmd: kubeadm_init
# todo else -> taint the node
{% endif %}

{% if kubernetes.master.upload_config %}
kubernetes_upload_config:
  module.run:
    - cp.push:
      - path: {{ kubernetes.config.locations|first }}
    - require:
      - cmd: kubeadm_init
{% endif %}

{% if masters|length > 1 %}
propagate_cert_key:
  module.run:
    - mine.send:
        - kubernetes_cert_key
        - mine_function: cmd.run
        - "kubeadm alpha certs certificate-key"
        - saltenv: {{ saltenv }}
    - require:
      - cmd: kubeadm_init
{% endif %}

propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: cmd.script
        - {{ kubernetes.master.token_script }}
        - saltenv: {{ saltenv }}
    - require:
      - cmd: kubeadm_init

propagate_hash:
  module.run:
    - mine.send:
        - kubernetes_hash
        - mine_function: cmd.run
        - "openssl x509 -pubkey -in {{ kubernetes.config.ca_cert }} | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'"
        - python_shell: True
    - require:
      - cmd: kubeadm_init

propagate_ip:
  module.run:
    - mine.send:
        - kubernetes_master_ip
        - mine_function: network.ip_addrs
        - cidr: {{ kubernetes_network.nodes.cidr }}
    - require:
      - cmd: kubeadm_init

#todo the cmd.run should be wrapped with script and return stateful data
{% endif %}
