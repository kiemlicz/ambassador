{% from "os/pkgs/map.jinja" import pkgs, pip_provider with context %}
{% from "_common/util.jinja" import retry, pkg_latest_opts with context %}

{% if pkgs.dist_upgrade %}
dist-upgrade:
  pkg.uptodate:
    - name: upgrade_os
    - refresh: True
    - force_yes: True
    - require:
      - sls: os.locale
      - sls: os.groups
    - require_in:
      - pkg: os_packages
{% endif %}

# any pkg.* that depends on this state for performance reasons, should not use refresh: True
pkgs:
  pkg.latest:
    - name: os_packages
    - pkgs: {{ pkgs.os_packages|tojson }}
{{ pkg_latest_opts() | indent(4) }}
    - reload_modules: True
    - require:
      - sls: os.locale
      - sls: os.groups

{%- if pkgs.fromrepo is defined and pkgs.fromrepo %}
{%- for fromrepo_config in pkgs.fromrepo %}
pkgs_fromrepo_{{ fromrepo_config.from }}:
  pkg.latest:
    - pkgs: {{ fromrepo_config.pkgs | tojson }}
    - fromrepo: {{ fromrepo_config.from }}
    - only_upgrade: {{ fromrepo_config.only_upgrade|default(False) }}
{{ pkg_latest_opts() | indent(4) }}
    - reload_modules: True
    - require:
      - pkg: os_packages
{%- endfor %}
{%- endif %}

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
{%- if pkgs.pip_user is defined %}
    - user: {{ pkgs.pip_user }}
{%- endif %}
    - require:
      - pkg: pip_provider
{% endif %}

{% if pkgs.pip3_packages is defined and pkgs.pip3_packages %}
# todo upgrading pip must be handled separately
# it will switch default /usr/bin/pip3 to /usr/local/bin/pip3
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
{%- if pkgs.pip3_user is defined %}
    - user: {{ pkgs.pip3_user }}
{%- endif %}
    - require:
      - pkg: pip3_provider
{% endif %}

{%- if pkgs.purged is defined and pkgs.purged %}
pkgs_purged:
  pkg.purged:
    - pkgs: {{ pkgs.purged|tojson }}
    - reload_modules: True
    - require:
      - pkg: os_packages
{%- endif %}
