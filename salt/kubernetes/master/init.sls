#included at top most directory as multiple `include:` statements are not allowed within one YAML
{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- if not kubernetes.nodes.masters %}
{{ raise("Kubernetes master nodes not specified") }}
{%- endif %}

include:
  - {{ kubernetes.container.runtime }}
{% if kubernetes.distro == "kubeadm" %}
  - kubernetes.distro.kubeadm.master
  - kubernetes.master.kubeadm.setup # kubeadm specific, refactor to be used like worker
{% elif kubernetes.distro == "k3s" %}
  - kubernetes.distro.k3s.master
{% endif %}
  - kubernetes.network
