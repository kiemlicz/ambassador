rclone:
  configs:
  - name: /etc/systemd/system/rclone-user.service
    service_name: rclone-user
    contents: |
      [Unit]
      Description=Google Drive (rclone)
      AssertPathIsDirectory=/mnt/userdir
      After=network-online.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/rclone mount \
              --config=/home/userdir/.config/rclone/rclone.conf \
              --allow-other \
              --cache-tmp-upload-path=/tmp/rclone/upload \
              --cache-chunk-path=/tmp/rclone/chunks \
              --cache-workers=8 \
              --cache-writes \
              --cache-dir=/tmp/rclone/vfs \
              --cache-db-path=/tmp/rclone/db \
              --vfs-cache-mode full \
              --no-modtime \
              --drive-use-trash \
              --stats=0 \
              --checkers=16 \
              --bwlimit=40M \
              --dir-cache-time=5h \
              --cache-info-age=60m userdir:/ /mnt/userdir
      ExecStop=/bin/fusermount -u /mnt/userdir
      Restart=always
      RestartSec=10
      User=user
      Group=user

      [Install]
      WantedBy=default.target
      WantedBy=multi-user.target