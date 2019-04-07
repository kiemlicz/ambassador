{% from "kubernetes/helm/map.jinja" import helm with context %}
{% from "kubernetes/master/map.jinja" import kubernetes with context %}

helm:
  cmd.script:
    - name: {{ helm.installer_url }}
    - env: {{ helm.options }}

helm_init:
  cmd.run:
    - name: "helm init"
    - runas: {{ helm.owner }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
