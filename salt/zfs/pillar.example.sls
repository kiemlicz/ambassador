zfs:
  # optional: install from backports and pin it, so ZFS DKMS follows a backports kernel
  fromrepo: {{ grains['oscodename'] }}-backports
  preferences_pin: release n={{ grains['oscodename'] }}-backports
  preferences_priority: 1100
  module_params:
    zfs_arc_max: 8589934592 # 8 GiB
    zfs_arc_min: 2147483648 # 2 GiB
  defaults: # /etc/default/zfs
    ZPOOL_IMPORT_PATH: '"/dev/disk/by-id"' # scan import keeps stable by-id vdev names
  pools:
    tank:
      create: False # one-shot flag, pass via CLI pillar only
      properties: # zpool create -o
        ashift: 12
        autotrim: "off"
        autoexpand: "on"
        cachefile: none # import by device scan (zfs-import-scan), a pool missing on one boot isn't dropped
      filesystem_properties: # zpool create -O, used only on creation
        compression: lz4
        atime: "off"
        xattr: sa
        acltype: posixacl
        dnodesize: auto
        normalization: formD
        canmount: "off"
        mountpoint: /tank
      layout:
        - mirror:
            - /dev/disk/by-id/ata-DISK_A
            - /dev/disk/by-id/ata-DISK_B
        - mirror:
            - /dev/disk/by-id/ata-DISK_C
            - /dev/disk/by-id/ata-DISK_D
    single:
      layout:
        - /dev/disk/by-id/ata-DISK_E
  datasets:
    tank/s3:
      properties:
        recordsize: 1M
        quota: 16T
    tank/shares/someone:
      user: someone
      group: someone
      mode: "0750"
    single/data:
      user: "1000"
      group: "1000"
      mode: "0775"
      dirs:
        - media/vids
        - library/vids
  sanoid:
    templates:
      shares:
        hourly: 24
        daily: 30
        monthly: 6
        autosnap: "yes"
        autoprune: "yes"
    datasets:
      tank/shares:
        use_template: shares
        recursive: "yes"