samba:
  pam_mount_conf: /etc/security/pam_mount.conf.xml
  pam_mount_conf_managed: salt://samba/pam_mount.conf.xml
  pkgs:
    - samba
  service_name: smb
