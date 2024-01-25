minion:
  health_file: /var/tmp/salt-health
  startup:
    pkgs:
    - python3-apt
    pip3:
    - pip==20.3.3
    - six>1.13.0
