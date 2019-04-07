{% from "robomongo/map.jinja" import robomongo with context %}
{% from "_macros/dev_tool.macros.jinja" import link_to_bin with context %}

include:
  - users

robomongo:
  devtool.managed:
    - name: {{ robomongo.generic_link }}
    - download_url: {{ robomongo.download_url }}
    - destination_dir: {{ robomongo.destination_dir }}
    - user: {{ robomongo.owner }}
    - group: {{ robomongo.owner }}
    - saltenv: {{ saltenv }}
    - require:
      - sls: users
{{ link_to_bin(robomongo.owner_link_location, robomongo.generic_link + '/bin/robo3t', robomongo.owner) }}
