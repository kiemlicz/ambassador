{% from "os/pkgs/map.jinja" import pkgs, pip_provider with context %}
{% from "_common/util.jinja" import retry with context %}

{% if pkgs.dist_upgrade %}
dist-upgrade:
  pkg.uptodate:
    - name: upgrade_os
    - refresh: True
    - force_yes: True
    - require:
      - sls: os.locale
    - require_in:
      - pkg: os_packages
{% endif %}

# any pkg.* that depends on this state for performance reasons, should not use refresh: True
pkgs:
  pkg.latest:
    - name: os_packages
    - pkgs: {{ pkgs.os_packages|tojson }}
    - refresh: True
    - reload_modules: True
    - require:
      - sls: os.locale

{% if pkgs.versions is defined and pkgs.versions %}
pkgs_versions:
  pkg.installed:
    - pkgs: {{ pkgs.versions|tojson }}
    - require:
      - pkg: os_packages
{{ retry(attempts=2)| indent(4) }}
{% endif %}

{% if pkgs.sources is defined and pkgs.sources %}
pkgs_sources:
  pkg.installed:
    - sources: {{ pkgs.sources|tojson }}
    - require:
      - pkg: os_packages
{{ retry(attempts=2)| indent(4) }}
{% endif %}

{% if pkgs.pip_packages is defined and pkgs.pip_packages %}
pip_provider:
  pkg.latest:
    - name: pip_provider
    - pkgs: {{ pip_provider.pip|tojson }}
    - reload_modules: True
    - require:
      - pkg: os_packages
pkgs_pip:
  pip.installed:
    - name: pip_packages
    - pkgs: {{ pkgs.pip_packages|tojson }}
    - reload_modules: True
    - require:
      - pkg: pip_provider
{% endif %}

{% if pkgs.pip3_packages is defined and pkgs.pip3_packages %}
pip3_provider:
  pkg.latest:
    - name: pip3_provider
    - pkgs: {{ pip_provider.pip3|tojson }}
    - reload_modules: True
    - require:
      - pkg: os_packages
pkgs_pip3:
  pip.installed:
    - name: pip3_packages
    - pkgs: {{ pkgs.pip3_packages|tojson }}
    - bin_env: '/usr/bin/pip3'
    - reload_modules: True
    - require:
      - pkg: pip3_provider
{% endif %}

{% if pkgs.scripts is defined and pkgs.scripts %}
{% for script in pkgs.scripts %}
pkgs_scripts_{{ script.source }}:
  cmd.script:
    - name: {{ script.source }}
    - args: {{ script.args }}
{% endfor %}
{% endif %}

{% if pkgs.post_install is defined and pkgs.post_install %}
post_install:
  cmd.run:
    - names: {{ pkgs.post_install|tojson }}
    - onchanges:
      - pkg: os_packages
{% endif %}
