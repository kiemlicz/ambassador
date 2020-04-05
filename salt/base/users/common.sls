{% from "_common/util.jinja" import retry with context %}

{% for username, user in salt['pillar.get']("users", {}).items() %}

{{ username }}_setup_user:
  user.present:
    - name: {{ username }}
    - fullname: {{ user.fullname|default(username) }}
    - shell: {{ user.shell|default("/bin/bash") }}
    # strip trailing /
    - home: {{ user.home_dir|default("/home/" ~ username)|regex_replace('/+$', '') }}
{%- if user.password is defined %}
    - password: {{ user.password }}
{% endif %}
{%- if user.groups is defined %}
    - groups: {{ user.groups|tojson }}
{%- endif %}
    - require:
      - sls: os # deliberately full sls (in case of urgent pkgs.post_install commands)

{%- if user.user_dirs is defined and user.user_dirs %}
{{ username }}_setup_directories:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 755
    - makedirs: True
    - names: {{ user.user_dirs|tojson }}
    - require:
      - user: {{ username }}
{%- endif %}

{%- if user.user_excluded_dirs is defined and user.user_excluded_dirs %}
{{ username }}_remove_directories:
  file.absent:
    - names: {{ user.user_excluded_dirs }}
    - require:
      - user: {{ username }}
{%- endif %}

{%- if user.git is defined %}
{% for k,v in user.git.items() %}
git_global_config_{{ username }}_{{ k }}:
  git.config_set:
    - name: {{ k }}
    - value: {{ v }}
    - user: {{ username }}
    - global: True
    - require:
      - user: {{ username }}
{% endfor %}
{%- endif %}

{% if user.known_hosts is defined %}
{{ username }}_setup_ssh_known_hosts:
  ssh_known_hosts.present:
    - names: {{ user.known_hosts|tojson }}
    - user: {{ username }}
{{ retry(attempts=2)| indent(4) }}
    - require:
      - user: {{ username }}
{% endif %}

{% endfor %}
