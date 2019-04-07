{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "_common/repo.jinja" import repository with context %}


{{ repository("kube_repository", kubernetes) }}
kubeadm:
    pkg.latest:
      - pkgs: {{ kubernetes.pkgs|tojson }}
      - refresh: True
      - require:
        - pkgrepo_ext: kube_repository
        - service: docker
