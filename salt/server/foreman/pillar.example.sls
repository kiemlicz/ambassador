{%- set fqdn = salt['network.get_fqdn']() %}
{%- set ip = "127.0.0.1" %}
{%- set interface = "lo" %}
{%- set reverse = salt['network.reverse_ip'](ip) %}
{%- set dnsserver = salt['grains.get']("dns:ip4_nameservers")|first %}
{%- set dnsdomain = salt['grains.get']("dns:domain") %}

foreman:
  fqdn: {{ fqdn }}
  installer_options:
    - "--no-enable-puppet"
    - "--puppet-server=false"
    - "--foreman-proxy-puppet=false"
    - "--foreman-proxy-puppetca=false"
    - "--foreman-proxy-puppet-group=foreman"
    - "--foreman-user-groups=EMPTY_ARRAY"
    - "--foreman-proxy-registered-name={{ fqdn }}"
    - "--foreman-proxy-registered-proxy-url=https://{{ fqdn }}:8443/"
    - "--foreman-proxy-tftp=true"
    - "--foreman-proxy-tftp-servername={{ ip }}"
    - "--foreman-proxy-dns=true"
    - "--foreman-proxy-dns-interface={{ interface }}"
    - "--foreman-proxy-dns-zone={{ dnsdomain }}"
    - "--foreman-proxy-dns-reverse={{ reverse }}"
    - "--foreman-proxy-dns-forwarders={{ dnsserver }}"
    - "--foreman-proxy-foreman-base-url=https://{{ fqdn }}"
  setup:
    - name: arch
      method: POST
      url: https://{{ fqdn }}/api/architectures
      header_dict:
        Accept: application/json
        Content-Type: application/json
      data: |
        {
          "architecture": {
            "name": "amd64"
          }
        }
