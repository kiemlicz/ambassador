kernel_modules:
  present:
    - name: coretemp
      persist: True
  absent:
    - name: novueau
      persist: True
