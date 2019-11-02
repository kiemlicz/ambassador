{% from "foreman/map.jinja" import foreman with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{%- set ip = salt['network.ip_addrs'](cidr="192.168.8.0/24")|first %}
{%- set fqdn = salt['network.get_fqdn']() %}

include:
  - os

{{ repo_pkg("foreman", foreman) }}

{% for config in foreman.config %}
foreman_{{ config.name }}:
  file.recurse:
    - name: {{ config.name }}
    - source: {{ config.source }}
    - template: jinja
    - clean: False
    - require:
      - pkg: foreman
    - require_in:
      - cmd: install_foreman
{% endfor %}

{%- for secret_name, secret in foreman.ssl.items() %}
foreman_{{ secret.name }}:
  x509.pem_managed:
    - name: {{ secret.name }}
    - text: {{ secret.text | yaml_encode }}
    - mode: {{ secret.mode|default(644) }}
{%- if secret.user is defined %}
    - user: {{ secret.user }}
{%- endif %}
{%- if secret.group is defined %}
    - group: {{ secret.group }}
{%- endif %}
    - makedirs: True
    - require:
      - pkg: foreman
    - require_in:
      - cmd: install_foreman
{%- endfor %}

ensure_fqdn_hosts:
  host.present:
    - names: {{ salt.dns_ext.aliases(fqdn) }}
    - ip: {{ ip }}
    - clean: True
    - require:
      - sls: os

install_foreman:
  cmd.run:
    - name: "foreman-installer {{ foreman.installer_options | join(' ') }}"
    - require:
      - sls: os
      - host: ensure_fqdn_hosts

{%- for service in foreman.services %}
{{ service }}_service:
  service.running:
    - name: {{ service }}
    - enable: True
    - watch:
      - cmd: install_foreman
{%- endfor %}
