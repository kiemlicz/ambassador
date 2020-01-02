users:
  vagrant:
    projects:
      - url: https://github.com/kiemlicz/ambassador
        target: /home/vagrant/projects/ambassador
        cmds:
          - "cd /home/vagrant/projects/ambassador/.test"
          - "bundler install"
