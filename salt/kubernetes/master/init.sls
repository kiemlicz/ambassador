#included at top most directory as multiple `include:` statements are not allowed within one YAML
{%- from "kubernetes/master/map.jinja" import kubernetes with context %}
{%- if not kubernetes.nodes.masters %}
{{ raise("Kubernetes master nodes not specified") }}
{%- endif %}

include:
  - docker
  - kubernetes.kubeadm
  - kubernetes.master.setup
  - kubernetes.network
