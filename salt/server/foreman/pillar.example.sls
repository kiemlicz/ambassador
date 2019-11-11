{%- set fqdn = salt['network.get_fqdn']() %}
{%- set ip = salt['network.ip_addrs'](cidr="127.0.0.0/24", include_loopback=True)|first %}
{%- set interface = salt['network.ifacestartswith'](cidr="127.0.0")|first %}
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
