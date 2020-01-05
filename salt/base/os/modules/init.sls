{% from "os/modules/map.jinja" import kernel_modules with context %}

{%- for kmod in kernel_modules.present %}
kmod_loaded_{{ kmod.name }}:
  kmod.present:
    - name: {{ kmod.name }}
    - persist: {{ kmod.persist }}
    - require:
      - sls: os.pkgs
{%- endfor %}

{%- for kmod in kernel_modules.absent %}
kmod_unloaded_{{ kmod.name }}:
  kmod.absent:
    - name: {{ kmod.name }}
    - persist: {{ kmod.persist }}
    - require:
      - sls: os.pkgs
{%- endfor %}
