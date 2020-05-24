{% from "os/hosts/map.jinja" import hosts with context %}


{% for address, aliases in hosts.items() %}
{{ address }}_host:
  host.present:
    - ip: {{ address }}
    - names: {{ aliases|tojson }}
{% endfor %}

hosts-notification:
  test.succeed_without_changes:
    - name: Hosts setup completed
