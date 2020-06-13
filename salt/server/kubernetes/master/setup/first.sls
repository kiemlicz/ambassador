# fixme install LB first
{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context -%}

{%- if kubernetes.nodes.masters|length > 1 %}
# for now assuming keepalived
{%- set cmd = "kubeadm init --control-plane-endpoint {{ kubernetes_network.nodes.master_vip }} --upload-certs" %}
{%- else %}
# single plane
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/
{%- set cmd = "kubeadm init --pod-network-cidr " ~ kubernetes_network.network.cidr %}
{%- endif %}

kubeadm_init:
  cmd.run:
    - name: {{ cmd }}
    - require:
      - pkg: kubeadm
    - require_in:
      - sls: kubernetes.network.{{ kubernetes_network.network.provider }}
    - unless: test -f /etc/kubernetes/admin.conf

{%- if kubernetes.master.upload_config %}
kubernetes_upload_config:
  module.run:
    - cp.push:
      - path: {{ kubernetes.config.locations|first }}
    - require:
      - cmd: kubeadm_init
{%- endif %}
