{%- from "kubernetes/map.jinja" import kubernetes with context %}
{%- from "_common/repo.jinja" import repository with context %}
{%- from "_common/util.jinja" import pkg_latest_opts with context %}

{{ repository("kube_repository", kubernetes) }}
kubeadm:
  pkg.latest:
    - pkgs: {{ kubernetes.pkgs|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo_ext: kube_repository
      - service: docker
