{% from "scala/map.jinja" import scala with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}
{% from "_common/util.jinja" import retry with context %}


include:
  - users


scala:
  devtool.managed:
    - name: {{ scala.generic_link }}
    - download_url: {{ scala.download_url }}
    - destination_dir: {{ scala.destination_dir }}
    - user: {{ scala.owner }}
    - group: {{ scala.owner }}
    - saltenv: {{ saltenv }}
{{ retry()| indent(4) }}
    - require:
      - sls: users
{{ add_environmental_variable(scala.environ_variable, scala.generic_link, scala.exports_file) }}
{{ add_to_path(scala.environ_variable, scala.path_inside, scala.exports_file) }}
