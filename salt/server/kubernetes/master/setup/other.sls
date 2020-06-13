{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context -%}

{%- set masters = kubernetes.nodes.masters %}
{%- set tokens = salt['mine.get'](masters|join(","), "kubernetes_token", tgt_type="list") %}
{%- set ips = salt['mine.get'](masters|join(","), "kubernetes_master_ip", tgt_type="list") %}
{%- set hashes = salt['mine.get'](masters|join(","), "kubernetes_hash", tgt_type="list") %}
{%- set cert_key = salt['mine.get'](masters|join(","), "kubernetes_cert_key", tgt_type="list") %}
{%- set main_master_id = ips.keys()|sort|first %}
{%- set cmd = "kubeadm join --token " ~ tokens[main_master_id]['stdout'] ~ " " ~ ips[main_master_id][0] ~ ":" ~ kubernetes_network.nodes.port ~ " --discovery-token-ca-cert-hash sha256:" ~ hashes[main_master_id] ~ " --control-plane --certificate-key " ~ cert_key[main_master_id] %}

kubeadm_init:
  cmd.run:
    - name: {{ cmd }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.network.{{ kubernetes_network.network.provider }}
    - unless: test -f /etc/kubernetes/admin.conf
