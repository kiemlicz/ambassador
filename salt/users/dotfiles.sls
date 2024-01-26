{% for username, user in salt['pillar.get']("users", {}).items() if user.dotfile is defined %}

{{ username }}_dotfiles:
  dotfile.managed:
    - name: {{ user.dotfile.repo }}
    - home_dir: {{ user.home_dir }}
    - username: {{ username }}
    - branch: {{ user.dotfile.branch }}
    - target: {{ user.dotfile.root }}
    - render: {{ user.dotfile.render|default(False) }}
    - override: {{ user.dotfile.override|default(False) }}
    - identity: {{ user.sec.ssh.dotfile.privkey_location}}
    - unless: {{ user.dotfile.unless|default(False) }}
    - onlyif: {{ user.dotfile.onlyif|default(True) }}
    - require:
      - sls: users.keys
      - sls: users.common
#todo fallback location = home
{% if user.dotfile.post_cmds is defined %}
  cmd.run:
    - names: {{ user.dotfile.post_cmds|tojson }}
    - runas: {{ username }}
    # causes setting use_sudo and running commands via `sudo`, not `su -`
    - group: {{ username }}
    - cwd: {{ user.dotfile.root }}
    - onchange:
      - dotfile: {{ user.dotfile.repo }}
{% endif %}

{% endfor %}
