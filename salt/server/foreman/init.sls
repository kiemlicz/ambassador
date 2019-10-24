{% from "foreman/map.jinja" import foreman with context %}
{% from "_macros/dev_tool.macros.jinja" import repo_pkg with context %}


include:
  - os


{{ repo_pkg("foreman", foreman) }}

{% for config in salt['pillar.get']("foreman:config", []) %}
foreman_{{ config.name }}:
  file.recurse:
    - name: {{ config.name }}
    - source: {{ foreman.source }}
    - template: jinja
    - clean: False
    - require:
      - pkg: foreman
    - require_in:
      - cmd: install_foreman
{% endfor %}

# fixme same with certs (list)

foreman_ca_certificate:
  x509.pem_managed:
    - name: {{ foreman.ca_cert_location }}
    - text: {{ foreman.ca-cert | yaml_encode }}
    - require:
      - pkg: foreman

foreman_server_certificate:
  x509.pem_managed:
    - name: {{ foreman.server_cert_location }}
    - text: {{ foreman.server-cert | yaml_encode }}
    - require:
      - pkg: foreman

foreman_server_proxy_certificate:
  x509.pem_managed:
    - name: {{ foreman.server_proxy_cert_location }}
    - text: {{ foreman.server-proxy-cert | yaml_encode }}
    - require:
      - pkg: foreman

foreman_server_key:
  x509.pem_managed:
    - name: {{ foreman.server_key_location }}
    - text: {{ foreman.server-key | yaml_encode }}
    - require:
      - pkg: foreman

foreman_server_proxy_key:
  x509.pem_managed:
    - name: {{ foreman.server_proxy_key_location }}
    - text: {{ foreman.server-proxy-key | yaml_encode }}
    - require:
      - pkg: foreman

foreman_crl:
  x509.pem_managed:
    - name: {{ foreman.server_crl_location }}
    - text: {{ foreman.crl | yaml_encode }}
    - require:
      - pkg: foreman

install_foreman:
  cmd.run:
    - name: "foreman-installer {{ foreman.installer_options | join(' ') }}"
    - require:
      - x509: foreman_ca_certificate
      - x509: foreman_server_certificate
      - x509: foreman_server_proxy_certificate
      - x509: foreman_server_key
      - x509: foreman_server_proxy_key
      - x509: foreman_crl
      - sls: os
