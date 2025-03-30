{%- from "kubernetes/distro/k3s/map.jinja" import k3s with context %}
{%- from "kubernetes/distro/k3s/_install.macros.jinja" import k3s_install with context %}
{%- set masters = k3s.nodes.masters %}
{%- set kube_api_ip = k3s.config.kubevip.vip %}
{%- set envs = k3s.distro_config.env %}
{%- if k3s.distro_config.existing_token is defined %}
{%- set multi_master_token = k3s.distro_config.existing_token  %}
{%- else %}
{%- set multi_master_token = salt['random.get_str'](length=100, punctuation=False) %}
{%- endif %}

include:
  - kubernetes.distro.requisites
  - kubernetes.distro.k3s.config
{%- if masters|length > 1 %}
{%- if grains['id'] == masters|first %}
  - .first

# token for multi-master is generated upfront
create_token:
  file.managed:
    - name: {{ k3s.distro_config.token_file ~ "-multi-master" }}
    - makedirs: True
    - contents: {{ multi_master_token }}
    - template: jinja
    - require:
      - cmd: k3s

propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: file.read
        - {{ k3s.distro_config.token_file ~ "-multi-master" }}
    - require:
      - file: create_token

{%- do envs.append({'K3S_TOKEN': multi_master_token | regex_replace('\n','') }) %}
{{ k3s_install(k3s.distro_config.installer_url, envs, "server --cluster-init --tls-san=" ~ kube_api_ip) }}
{%- else %}
# other masters from multi-master

{%- set tokens = salt['mine.get'](masters|first, "kubernetes_token") %}
{%- do envs.append({'K3S_TOKEN': tokens[masters|first] | regex_replace('\n','') }) %}
# this is file content thus contains new line, which breaks agent join
{{ k3s_install(k3s.distro_config.installer_url, envs, k3s.distro_config.args) }}

{%- endif %}

{%- else %}
# single master setup

{{ k3s_install(k3s.distro_config.installer_url, k3s.distro_config.env) }}

# token is propagated after the single master is installed
propagate_token:
  module.run:
    - mine.send:
        - kubernetes_token
        - mine_function: file.read
        - {{ k3s.distro_config.token_file }}
    - require:
      - cmd: k3s
{%- endif %}
