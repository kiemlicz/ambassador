{% from "rebar/map.jinja" import rebar with context %}
{% from "_macros/dev_tool.macros.jinja" import add_environmental_variable,add_to_path with context %}


include:
  - users
  - erlang


rebar:
  git.latest:
    - name: {{ rebar.git_url }}
    - target: {{ rebar.destination_dir }}/{{ rebar.orig_name }}
    - require:
      - sls: erlang
  file.symlink:
    - name: {{ rebar.generic_link }}
    - target: {{ rebar.destination_dir }}/{{ rebar.orig_name }}
    - user: {{ rebar.owner }}
    - require:
      - sls: users
      - git: {{ rebar.git_url }}
rebar_change_owner:
  file.directory:
    - name: {{ rebar.destination_dir }}/{{ rebar.orig_name }}
    - user: {{ rebar.owner }}
    - group: {{ rebar.owner }}
    - recurse:
      - user
      - group
    - require:
      - sls: users
      - git: {{ rebar.git_url }}
  cmd.script:
    - name: {{ rebar.generic_link }}/bootstrap
    - runas: {{ rebar.owner }}
    - cwd: {{ rebar.destination_dir }}/{{ rebar.orig_name }}/
    - env:
      - HOME: {{ rebar.owner_home_dir }}
    - require:
      - sls: users
      - file: {{ rebar.destination_dir }}/{{ rebar.orig_name }}

update_environment_rebar:
{{ add_environmental_variable(rebar.environ_variable, rebar.generic_link, rebar.exports_file) }}
{{ add_to_path(rebar.environ_variable, rebar.path_inside, rebar.exports_file) }}
    - require:
      - cmd: {{ rebar.generic_link }}/bootstrap
