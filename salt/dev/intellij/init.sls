{% from "intellij/map.jinja" import intellij with context %}
{% from "_macros/dev_tool.macros.jinja" import link_to_bin with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


intellij:
  devtool.managed:
    - name: {{ intellij.generic_link }}
    - download_url: {{ intellij.download_url }}
    - destination_dir: {{ intellij.destination_dir }}
    - user: {{ intellij.owner }}
    - group: {{ intellij.owner }}
    - saltenv: {{ saltenv }}
{{ retry()| indent(4) }}
    - require:
      - sls: users
{{ link_to_bin(intellij.owner_link_location, intellij.generic_link + '/bin/idea.sh', intellij.owner) }}
