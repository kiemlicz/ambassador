{% from "os/services/map.jinja" import services with context %}
{#- keys other than 'list' holding a mapping are services with drop-in configs #}
{%- set dropins = {} %}
{%- for name, conf in services.items() if name != 'list' and conf is mapping %}
{%- do dropins.update({name: conf}) %}
{%- endfor %}

{%- for service, conf in dropins.items() %}
{%- set dropin_dir = conf.get('dir', services.dropins_dir ~ service ~ '.service.d') %}
{%- for name, contents in conf.files.items() %}
{{ service }}_dropin_{{ name }}:
  file.managed:
    - name: {{ dropin_dir ~ '/' ~ name }}
    - contents: {{ contents|yaml_encode }}
    - makedirs: True
    - replace: True
{%- endfor %}
{%- endfor %}

{% for service in services.list + (dropins.keys()|reject('in', services.list)|list) %}
{{ service }}:
  service.running:
    - name: {{ service }}
{%- if service in services.list %}
    - enable: True
{%- endif %}
    - require:
      - pkg: os_packages
{%- if service in dropins %}
    - watch:
{%- for name in dropins[service].files %}
      - file: {{ service }}_dropin_{{ name }}
{%- endfor %}
{%- endif %}
{% endfor %}
