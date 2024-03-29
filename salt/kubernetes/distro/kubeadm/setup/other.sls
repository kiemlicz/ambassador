{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/cni/map.jinja" import kubernetes as kubernetes_cni with context -%}

{%- set masters = kubernetes.nodes.masters %}
{%- set main_master_id = kubernetes.nodes.masters|first %}
{%- set tokens = salt['mine.get'](masters|join(","), "kubernetes_token", tgt_type="list") %}
{%- set ips = salt['mine.get'](masters|join(","), "kubernetes_master_ip", tgt_type="list") %}
{%- set hashes = salt['mine.get'](masters|join(","), "kubernetes_hash", tgt_type="list") %}
{%- set cert_key = salt['mine.get'](masters|join(","), "kubernetes_cert_key", tgt_type="list") %}
{%- set cmd = "kubeadm join " ~ ips[main_master_id][0] ~ ":" ~ kubernetes_cni.nodes.apiserver_port ~ " --token " ~ tokens[main_master_id]|selectattr('usages', 'match', '.*authentication.*')|map(attribute="token")|first ~ " --discovery-token-ca-cert-hash sha256:" ~ hashes[main_master_id] ~ " --control-plane --certificate-key " ~ cert_key[main_master_id] %}

kubeadm_init:
  cmd.run:
    - name: {{ cmd }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.cni.{{ kubernetes_cni.cni.provider }}
    - unless: test -f /etc/kubernetes/admin.conf
