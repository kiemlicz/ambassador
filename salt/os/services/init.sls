{% from "os/services/map.jinja" import services with context %}


{% for service in services.list %}
{{ service }}:
  service.running:
    - name: {{ service }}
    - enable: True
    - require:
      - pkg: os_packages
{% endfor %}
