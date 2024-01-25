{% from "ghrunner/map.jinja" import ghrunner with context %}
{% from "_common/util.jinja" import retry with context %}

include:
  - users

ghrunner:
  devtool.managed:
    - name: {{ ghrunner.generic_link }}
    - download_url: {{ ghrunner.download_url }}
    - destination_dir: {{ ghrunner.destination_dir }}
    - user: {{ ghrunner.owner }}
    - group: {{ ghrunner.owner }}
    - saltenv: {{ saltenv }}
{{ retry(attempts=2, interval=60)| indent(4) }}
    - require:
      - sls: users
