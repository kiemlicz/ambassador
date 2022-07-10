{% from "argocd/map.jinja" import argocd with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


argocd:
  file.managed:
    - name: {{ argocd.location }}
    - source: {{ argocd.download_url }}
    - user: {{ argocd.owner }}
    - group: {{ argocd.owner }}
    - skip_verify: True
    - mode: 755
{{ retry()| indent(4) }}
    - require:
      - sls: users
