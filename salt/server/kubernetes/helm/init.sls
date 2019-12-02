{% from "kubernetes/helm/map.jinja" import helm with context %}
{% from "kubernetes/master/map.jinja" import kubernetes with context %}

helm:
  cmd.script:
    - name: {{ helm.installer_url }}
    - env: {{ helm.options }}

{% if helm.perform_init %}
helm_init:
  cmd.run:
    - name: "helm init"
    - runas: {{ helm.owner }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
{% endif %}

{% for plugin in helm.plugins %}
helm_plugin_{{ plugin }}:
  cmd.run:
    - name: "helm plugin install {{ plugin }}"
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
{% endfor %}
