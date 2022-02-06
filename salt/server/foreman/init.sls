{% from "foreman/map.jinja" import foreman with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}
{%- set ip = salt['network.ip_addrs'](cidr=foreman.cidr)|first %}
{%- set fqdn = foreman.fqdn %}

include:
  - os

{{ repo_pkg("foreman", foreman) }}

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
{%- if salt['service.enabled']("systemd-resolved") %}
# in order to force systemd-resolved to return proper fqdn
  file.symlink:
    - name: /etc/resolv.conf
    - target: /run/systemd/resolve/resolv.conf
    - require:
      - host: ensure_fqdn_hosts

{%- endif %}

install_foreman:
  cmd.run:
    - name: "foreman-installer {{ foreman.installer_options | join(' ') }}"
    - require:
      - sls: os
      - host: ensure_fqdn_hosts

{% for config in foreman.config %}
foreman_{{ config.name }}:
  file.recurse:
    - name: {{ config.name }}
    - source: {{ config.source }}
    - template: jinja
    - clean: False
{%- if config.user is defined %}
    - user: {{ config.user }}
{%- endif %}
{%- if config.group is defined %}
    - group: {{ config.group }}
{%- endif %}
    - require:
      - pkg: foreman
      - cmd: install_foreman
{% endfor %}

{%- for service in foreman.services %}
{{ service }}_service:
  service.running:
    - name: {{ service }}
    - enable: True
    - watch:
      - cmd: install_foreman
{%- endfor %}

{%- for query in foreman.setup %}
setup_foreman_{{ query.name }}:
    #fixme make it fail on non 2XX status
  module.run:
    - http.query:
      - {{ query.url }}
      - header_dict:
            Accept: application/json
            Content-Type: application/json
      - method: {{ query.method }}
{%- if query.data is defined %}
      - data: {{ query.data|tojson|yaml_squote }}
{%- endif %}
{%- if foreman.foreman_username is defined and foreman.foreman_password is defined %}
      - username: {{ foreman.foreman_username }}
      - password: {{ foreman.foreman_password }}
{%- endif %}
      - verify_ssl: {{ query.verify_ssl|default(True) }}
{%- if query.ca_bundle is defined %}
      - ca_bundle: {{ query.ca_bundle }}
{%- endif %}
{%- if query.cert is defined %}
      - cert: {{ query.cert }}
{%- endif %}
    - require:
      - cmd: install_foreman
{%- endfor %}

{% for override in foreman.overrides %}
foreman_override_{{ override.name }}:
  file_ext.managed:
    - name: {{ override.name }}
{%- if override.contents is defined %}
    - contents: {{ override.contents | yaml_encode }}
{%- elif override.source is defined %}
    - source: {{ override.source }}
{%- endif %}
{%- if override.template is defined %}
    - template: {{ override.template }}
{%- endif %}
{%- if override.mode is defined %}
    - mode: {{ override.mode }}
{%- endif %}
{%- if override.user is defined %}
    - user: {{ override.user }}
{%- endif %}
{%- if override.group is defined %}
    - group: {{ override.group }}
{%- endif %}
    - makedirs: True
    - skip_verify: True
    - require:
      - cmd: install_foreman
{% endfor %}
