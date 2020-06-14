# fixme install LB first
{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- from "kubernetes/network/map.jinja" import kubernetes as kubernetes_network with context -%}

{%- if kubernetes.nodes.masters|length > 1 %}
{%- if kubernetes.master.ca.host == grains['id'] %}
include:
- .ca
{%- endif %}

# https://kubernetes.io/docs/concepts/cluster-administration/certificates/
# https://kubernetes.io/docs/setup/best-practices/certificates/#certificate-paths
kubernetes_apiserver_key:
  x509.private_key_managed:
  - name: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.apiserver.priv }}"
  - bits: {{ kubernetes.master.apiserver.priv_keylen|default(4096) }}
  - backup: True
{%- if kubernetes.master.ca.host == grains['id'] %}
# if CA is co-located with first master node
  - require:
    - sls: kubernetes.master.setup.ca
{%- endif %}  

{%- set vip = kubernetes_network.nodes.master_vip.split('/')[0] %}
kubernetes_apiserver_cert:
  x509.certificate_managed:
  - name: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.apiserver.pub }}"
  - ca_server: {{ kubernetes.master.ca.host }}
  - signing_policy: kubernetes
  - public_key: "{{ kubernetes.master.pki.dir }}/{{ kubernetes.master.apiserver.priv }}"
  - CN: kube-apiserver
  - basicConstraints: "critical CA:false"
  - keyUsage: "critical digitalSignature, keyEncipherment"
  - extendedKeyUsage: "serverAuth"
  - subjectAltName: "{{ kubernetes.master.apiserver.subjectAltName }}, IP Address: {{ vip }}"
  - days_valid: 365
  - backup: True
  - require:
    - x509: kubernetes_apiserver_key

# for now assuming keepalived
# remove --upload-certs if certs issues
{%- set cmd = "kubeadm init --control-plane-endpoint " ~ vip ~ " --upload-certs" %}
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
