salt_installer:
  api:
    host: 0.0.0.0
    username: user
    password: password
  master:
    config:
      - name: /etc/salt/master.d/master.conf
        initial: True
        contents: |
          interface: 0.0.0.0
          gitfs_provider: pygit2
          gitfs_saltenv_whitelist:
            - base
            - dev
            - server
