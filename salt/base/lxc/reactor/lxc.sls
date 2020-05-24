# salt/lxc/*/created
lxc_init:
  runner.lxc.init:
    - args:
      - names: {{ data['data']['name'] }}
      - host: {{ data['id'] }}
      - profile: {{ data['data']['profile']|default(None) }}
      - network_profile: {{ data['data']['network_profile']|default(None) }}
      - template: {{ data['data']['template']|default(None) }}
      - seed: {{ data['data']['seed']|default(True) }}
      - install: {{ data['data']['install']|default(True) }}
{%- if 'bootstrap_args' in data['data'] %}
      - bootstrap_args: {{ data['data']['bootstrap_args'] }}
{%- endif %}
{%- if 'config' in data['data'] %}
      - config: {{ data['data']['config'] }}
{%- endif %}
