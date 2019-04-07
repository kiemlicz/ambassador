{% from "kubernetes/client/map.jinja" import kubernetes with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}


{{ repository("kube_repository", kubernetes) }}
kubectl:
  pkg.latest:
    - pkgs: {{ kubernetes.client.pkgs|tojson }}
    - refresh: True
    - require:
      - pkgrepo_ext: kube_repository
