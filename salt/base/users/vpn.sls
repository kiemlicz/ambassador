{% for username, user in salt['pillar.get']("users", {}).items() if user.vpn is defined and user.vpn %}

{% for v in user.vpn %}

{% if v.source is defined %}
{{ username }}_vpn_{{ v.name }}_directory:
  file.recurse:
    - name: {{ v.location }}/{{ v.name }}
    - source: {{ v.source }}
{% if v.include_pat is defined %}
    - include_pat: {{ v.include_pat }}
{% endif %}
{% if v.exclude_pat is defined %}
    - exclude_pat: {{ v.exclude_pat }}
{% endif %}
    - file_mode: 600
    - user: {{ username }}
    - require:
      - user: {{ username }}

{% elif v.contents is defined or v.source_file is defined %}
# fixme it is not possible to setup VPN using contents
{{ username }}_vpn_{{ v.name }}_file:
  file.managed:
    - name: {{ v.location }}/{{ v.name }}
{% if v.contents is defined %}
    - contents: {{ v.contents | yaml_encode }}
{% elif v.source_file is defined %}
    - source: {{ v.source_file }}
{% else %}
    - contents: {{ v.config | yaml_encode }}
{% endif %}
    - user: {{ username }}
    - mode: 600
    - makedirs: True
    - require:
      - user: {{ username }}
{% endif %}

{% endfor %}
{# somehow empty notification is not needed here #}
{% endfor %}
