{% from "gradle/map.jinja" import gradle with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


gradle:
  devtool.managed:
    - name: {{ gradle.generic_link }}
    - download_url: {{ gradle.download_url }}
    - destination_dir: {{ gradle.destination_dir }}
    - user: {{ gradle.owner }}
    - group: {{ gradle.owner }}
    - saltenv: {{ saltenv }}
{{ retry()| indent(4) }}
    - require:
      - sls: users
{{ add_environmental_variable(gradle.environ_variable, gradle.generic_link, gradle.exports_file) }}
{{ add_to_path(gradle.environ_variable, gradle.path_inside, gradle.exports_file) }}
