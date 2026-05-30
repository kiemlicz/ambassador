{%- for username, user in salt['pillar.get']("users", {}).items() if user.sec is defined and user.sec %}

  {%- if user.sec.ssh is defined %}
  {%- for name, key_spec in user.sec.ssh.items() %}
  {% if key_spec.privkey is defined %}
{{username}}_copy_{{name}}_ssh_priv:
  file.managed:
    - name: {{ key_spec.privkey_location }}
    - contents_pillar: users:{{username}}:sec:ssh:{{name}}:privkey
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - makedirs: True
    - require:
        - user: {{ username }}
{{username}}_copy_{{name}}_ssh_pub:
  file.managed:
    - name: {{ key_spec.pubkey_location }}
    - contents_pillar: users:{{username}}:sec:ssh:{{name}}:pubkey
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - makedirs: True
    - require:
        - user: {{ username }}
  {% else %}
{{username}}_generate_{{name}}_ssh_keys:
  cmd.run:
  - name: "/usr/bin/ssh-keygen -q -t rsa -f {{ key_spec.privkey_location }} -N ''"
  - runas: {{ username }}
  - creates:
        - {{ key_spec.privkey_location }}
        - {{ key_spec.pubkey_location }}
  - require:
      - user: {{username}}
  {% endif %}
  {%- endfor %}
  {%- endif %}

  {%- if user.sec.ssh_authorized_keys is defined %}
  {%- for key_spec in user.sec.ssh_authorized_keys %}
{{username}}_setup_ssh_authorized_keys:
    ssh_auth.present:
      - names: {{ key_spec.names|tojson }}
      - user: {{ username }}
      - enc: {{ key_spec.enc }}
  {%- endfor %}
  {%- endif %}

{%- endfor %}
