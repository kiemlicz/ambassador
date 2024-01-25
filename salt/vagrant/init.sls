{% from "vagrant/map.jinja" import vagrant with context %}
{% from "_common/repo.jinja" import repository, preferences with context %}

include:
  - os
  - users

{{ repository("vagrant_repository", vagrant, require=[{'sls': "os"}], require_in=[{'pkg': 'vagrant'}]) }}

{% if vagrant.requisites is defined %}
vagrant_requisites:
  pkg.latest:
    - pkgs: {{ vagrant.requisites|tojson }}
    - require:
      - sls: os
    - require_in:
      - pkg: vagrant
{% endif %}

vagrant:
  pkg.installed:
    - pkgs: {{ vagrant.pkgs | tojson }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: os

{% if vagrant.plugins is defined %}
{% for plugin in vagrant.plugins %}

vagrant_plugin_{{ plugin.name }}:
{% if plugin.pkgs is defined %}
  pkg.latest:
  - pkgs: {{ plugin.pkgs|tojson }}
  - require:
    - pkg: vagrant
  - require_in:
    - cmd: vagrant_plugin_{{ plugin.name }}
{% endif %}
  cmd.run:
  - name: "{{ plugin.env|default("") }} vagrant plugin install {{ plugin.name }}"
  - runas: {{ vagrant.owner }}
  - require:
    - pkg: vagrant

{% endfor %}
{% endif %}
