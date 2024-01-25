{% from "os/hosts/map.jinja" import hosts with context %}

{%- if salt['service.enabled']("systemd-resolved") and not (salt.condition.podman() or salt.condition.docker()) %}
systemd_resolved_use_server_dns:
# in order to force systemd-resolved to return proper fqdn, cannot modify resolv.conf in docker
  file.symlink:
    - name: /etc/resolv.conf
    - target: /run/systemd/resolve/resolv.conf
{%- endif %}

{% for address, aliases in hosts.items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases|tojson }}
{% endfor %}

hosts-notification:
  test.succeed_without_changes:
    - name: Hosts setup completed
