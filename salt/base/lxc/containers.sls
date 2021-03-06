{% from "lxc/map.jinja" import lxc with context %}
{%- for name, container in lxc.containers.items() %}
lxc_container_{{ name }}:
  lxc.present:
    - name: {{ name }}
    - running: {{ container.running|default(None) }}
    - profile: {{ container.profile|default(None) }}
    - network_profile: {{ container.network_profile|default(None) }}
    - options: {{ container.options|default(None) }}
    - template: {{ container.template|default(None) }}
    - require:
      - sls: lxc.install
  event.send:
    - name: 'salt/lxc/{{ name }}/created'
    - data:
        name: {{ name }}
        profile: {{ container.profile|default(None) }}
        network_profile: {{ container.network_profile|default(None) }}
        template: {{ container.template|default(None) }}
        seed: {{ container.seed|default(True) }}
        install: {{ container.install|default(True) }}
{%- if container.bootstrap_args is defined %}
        bootstrap_args: {{ container.bootstrap_args }}
{%- endif %}
{%- if container.config is defined %}
        # this will be the minion's config, otherwise only id is set
        config: {{ container.config|tojson }}
{%- endif %}
    - require:
      - lxc: lxc_container_{{ name }}
{%- endfor %}

lxc-containers-notification:
  test.succeed_without_changes:
  - name: LXC containers setup completed
