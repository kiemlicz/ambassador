{% from "kubernetes/csi/map.jinja" import kubernetes with context %}


helm_longhorn_repo:
  helm.repo_managed:
    - present:
        - name: longhorn
          url: https://charts.longhorn.io

csi_longhorn_check_requisites:
  cmd.script:
    - name: {{ kubernetes.csi.config.check }}

#csi_longhorn_install:
#  helm.release_present:
#    - name: {{ kubernetes.csi.config.release_name }}
# todo incomplete as giving up on longhorn, now using openebs for local PV
