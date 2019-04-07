{% from "sbt/map.jinja" import sbt with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path,repo_pkg with context %}
{% from "_common/repo.jinja" import repository with context %}


include:
  - os
  - users


{{ repo_pkg("sbt_repository", sbt) }}

{{ add_environmental_variable(sbt.environ_variable, sbt.generic_link, sbt.exports_file) }}
{{ add_to_path(sbt.environ_variable, sbt.path_inside, sbt.exports_file) }}

# todo on windows need to find the dir
