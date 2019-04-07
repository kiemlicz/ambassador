{% from "os/locale/map.jinja" import locale with context %}
{% from "_common/util.jinja" import is_lxc with context %}


{% if locale.required_pkgs %}
required_pkgs:
  pkg.latest:
    - name:
    - pkgs: {{ locale.required_pkgs|tojson }}
    - require:
      - sls: os.repositories
    - require_in:
      - locale: gen_locale
{% endif %}

gen_locale:
  locale.present:
    - names: {{ locale.locales|tojson }}

{% if not is_lxc()|to_bool %}
default_locale:
  locale.system:
    - name: {{ locale.system_default }}
    - require:
      - locale: gen_locale
{% endif %}
