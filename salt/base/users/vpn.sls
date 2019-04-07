{% for username, user in salt['pillar.get']("users", {}).items() if user.vpn is defined and user.vpn %}

{% for v in user.vpn %}
{% set vpn_config = '{}_vpn_{}_config'.format(username, v.name) %}

{% if v.source is defined %}
{{ username }}_vpn_{{ v.name }}_directory:
  file_ext.recurse:
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

{% elif pillar[vpn_config] is defined or v.source_file is defined %}

{{ username }}_vpn_{{ v.name }}_file:
  file_ext.managed:
    - name: {{ v.location }}/{{ v.name }}
{% if pillar[vpn_config] is defined %}
    - contents_pillar: {{ vpn_config }}
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
