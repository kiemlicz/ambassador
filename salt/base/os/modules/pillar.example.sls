kernel_modules:
  absent:
    - name: novueau
      persist: True
---
kernel_modules:
  present:
    - name: coretemp
      persist: True
  absent:
    - name: novueau
      persist: True
