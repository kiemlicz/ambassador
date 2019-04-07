{% for username, user in salt['pillar.get']("users", {}).items() if user.dotfile is defined %}

{{ username }}_dotfiles:
  dotfile.managed:
    - require:
      - sls: users.common
      - sls: users.tools
      - sls: users.keys
      - user: {{ username }}
    - name: {{ user.dotfile.repo }}
    - home_dir: {{ user.home_dir }}
    - username: {{ username }}
    - branch: {{ user.dotfile.branch }}
    - target: {{ user.dotfile.root }}
    - render: {{ user.dotfile.render|default(False) }}
    - override: {{ user.dotfile.override|default(False) }}
    - identity: {{ user.sec.ssh.dotfile.privkey_location}}
    - saltenv: {{ saltenv }}
    - require:
      - sls: users.keys
#todo fallback location = home
{% if user.dotfile.post_cmds is defined %}
  cmd.run:
    - names: {{ user.dotfile.post_cmds|tojson }}
    - runas: {{ username }}
    - cwd: {{ user.dotfile.root }}
    - onchange:
      - dotfile: {{ user.dotfile.repo }}
{% endif %}

{% endfor %}
