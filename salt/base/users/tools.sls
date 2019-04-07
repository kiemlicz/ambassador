{% for username, user in salt['pillar.get']("users", {}).items() if user.tools is defined %}

{{ username }}_setup_oh_my_zsh:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.oh_my_zsh.url }}
    - target: {{ user.tools.oh_my_zsh.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}

{{ username }}_setup_oh_my_zsh_syntax_highlighting:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.oh_my_zsh_syntax_highlighting.url }}
    - target: {{ user.tools.oh_my_zsh_syntax_highlighting.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
      - git: {{ username }}_setup_oh_my_zsh

{{ username }}_fzf:
  git.latest:
    - user: {{ username }}
    - name: {{ user.tools.fzf.url }}
    - target: {{ user.tools.fzf.target }}
    - force_fetch: True
    - require:
      - user: {{ username }}
  cmd.run:
  # doesn't duplicate line appended to .zshrc
    - name: yes | {{ user.tools.fzf.target }}/install
    - runas: {{ username }}
    - onchange:
      - git: {{ username }}_fzf

{{ username }}_powerline_requirements:
  pkg.latest:
    - pkgs: {{ user.tools.powerline.required_pkgs|tojson }}
    - refresh: True
    - require:
      - user: {{ username }}

{{ username }}_powerline_python2:
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - install_options:
      - --user
    - require:
      - pkg: {{ username }}_powerline_requirements

{{ username }}_powerline_python3:
  pip.installed:
    - name: {{ user.tools.powerline.pip }}
    - user: {{ username }}
    - bin_env: '/usr/bin/pip3'
    - install_options:
      - --user
    - require:
      - pkg: {{ username }}_powerline_requirements

{% endfor %}
