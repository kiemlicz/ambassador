{% from "gatling/map.jinja" import gatling with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import retry with context %}

include:
  - users
  - java

gatling:
  devtool.managed:
    - name: {{ gatling.generic_link }}
    - download_url: {{ gatling.download_url }}
    - destination_dir: {{ gatling.destination_dir }}
    - user: {{ gatling.owner }}
    - group: {{ gatling.owner }}
    - saltenv: {{ saltenv }}
{{ retry(attempts=5, interval=60)| indent(4) }}
    - require:
      - sls: java
      - sls: users
{{ add_environmental_variable(gatling.environ_variable, gatling.generic_link, gatling.exports_file) }}
{{ add_to_path(gatling.environ_variable, gatling.path_inside, gatling.exports_file) }}
