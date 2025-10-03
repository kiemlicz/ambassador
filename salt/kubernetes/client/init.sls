{% from "kubernetes/client/map.jinja" import kubernetes with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}
{% from "_common/util.jinja" import pkg_latest_opts with context %}


{{ repository("kube_repository", kubernetes) }}
kubectl:
  pkg.latest:
    - pkgs: {{ kubernetes.client.pkgs|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - require:
      - pkgrepo: kube_repository
