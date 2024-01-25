{%- from "os/locale/map.jinja" import locale with context %}

{%- if locale.required_pkgs %}
required_pkgs:
  pkg.latest:
    - name: locale_required_pkgs
    - pkgs: {{ locale.required_pkgs|tojson }}
    - require:
      - sls: os.repositories
    - require_in:
      - locale: gen_locale
{% endif %}

gen_locale:
  locale.present:
    - names: {{ locale.locales|tojson }}

{%- if not salt.condition.lxc() %}
default_locale:
  locale.system:
    - name: {{ locale.system_default }}
    - require:
      - locale: gen_locale
{%- endif %}
