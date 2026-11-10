nfs:
  server:
    config: # /etc/nfs.conf sections
      nfsd:
        vers3: "n"
    exports:
      - path: /tank/shares/someone
        clients:
          - host: 192.168.1.0/24
            options: [rw, sync, no_subtree_check, mp] # mp: export only if a filesystem is mounted at path

# clients: install nfs-common (os packages), mounts are handled by os.mounts:
#mounts:
#  list:
#    - dev: "nas.lan:/tank/shares/someone"
#      target: /mnt/nas/someone
#      file_type: nfs4
#      options: [noauto, x-systemd.automount, x-systemd.idle-timeout=10min, _netdev, soft, timeo=150]
