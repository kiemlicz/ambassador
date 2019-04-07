{% from "maven/map.jinja" import maven with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import retry with context %}

include:
  - users

maven:
  devtool.managed:
    - name: {{ maven.generic_link }}
    - download_url: {{ maven.download_url }}
    - destination_dir: {{ maven.destination_dir }}
    - user: {{ maven.owner }}
    - group: {{ maven.owner }}
    - saltenv: {{ saltenv }}
{{ retry(attempts=8, interval=90)| indent(4) }}
    - require:
      - sls: users
{{ add_environmental_variable(maven.environ_variable, maven.generic_link, maven.exports_file) }}
{{ add_to_path(maven.environ_variable, maven.path_inside, maven.exports_file) }}
