kvm:
  prerequisites:
    - qemu-kvm
    - libvirt-clients
    - libvirt-daemon-system
  users:
    - coolguy
  vfio:
    enabled: True
    configs:
      - name: /etc/default/grub.d/vfio.cfg
        contents: |
          GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on iommu=pt"
