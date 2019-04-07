pkgs:
  dist_upgrade: True
  os_packages:
    - zsh
  versions:
    - "python-pip: 9.0.1-2.3"
  pip_packages:
    - pip_package
    - google-auth
  post_install:
    - some command
    - to be executed
  scripts:
    - source: http://example.com/somescript.sh
      args: "-a -b -c"
