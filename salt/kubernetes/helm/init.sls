{% from "kubernetes/helm/map.jinja" import helm with context %}
{% from "kubernetes/master/map.jinja" import kubernetes with context %}

helm:
  cmd.script:
    - name: {{ helm.installer_url }}
    - env: {{ helm.options }}

{%- for plugin in helm.plugins %}
helm_plugin_{{ plugin }}:
  cmd.run:
    - name: "helm plugin install {{ plugin }}"
    - runas: {{ helm.owner }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
{%- endfor %}

{%- for repo in helm.repositories %}
helm_repo_{{ repo.name }}:
  cmd.run:
    - name: "helm repo add {{ repo.name }} {{ repo.url }}"
    - runas: {{ helm.owner }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
    - require_in:
      - cmd: helm_repo_update
{%- endfor %}

{% if helm.repositories %}
helm_repo_update:
  cmd.run:
    - name: "helm repo update"
    - runas: {{ helm.owner }}
    - env:
        - KUBECONFIG: {{ kubernetes.config.locations|join(':') }}
    - require:
      - cmd: helm
{% endif %}
