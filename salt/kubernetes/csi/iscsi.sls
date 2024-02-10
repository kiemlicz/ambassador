{% from "kubernetes/csi/map.jinja" import kubernetes with context %}
# common for longhorn and openebs

iscsi_setup:
  pkg.latest:
    - pkgs: {{ kubernetes.csi.config.pkgs|tojson }}
  service.running:
    - name: {{ kubernetes.csi.config.service_name }}
    - enable: True
    - require:
      - pkg: iscsi_setup
