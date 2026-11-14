lvm:
  pkgs: ["lvm2", "thin-provisioning-tools"]
  modules: ["dm_thin_pool", "dm_snapshot"]
  services: ["dm-event.socket", "lvm2-monitor.service"]
  config: {}
  thinpool_monitor: False
  vgs: {}
#---
#lvm:
#  # rendered into /etc/lvm/lvmlocal.conf (overrides /etc/lvm/lvm.conf), section -> settings
#  config:
#    activation:
#      monitoring: 1
#      thin_pool_autoextend_threshold: 70
#      thin_pool_autoextend_percent: 20
#    devices:
#      issue_discards: 1
#  # udev rule registering newly created thin pools in dmeventd (needed for pools created by OpenEBS lvm-localpv)
#  thinpool_monitor: True
#  # VG -> PVs; use /dev/disk/by-id paths, /dev/sdX paths are skipped once the VG exists
#  vgs:
#    home-main-nvme:
#      - /dev/disk/by-id/nvme-CT2000P3SSD8_2451E99B0A37_1-part1
