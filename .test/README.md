# Self-hosted test environment
Due to numerous docker limitations tests should be performed in LXC container or even better: dedicated VMs

The most common way is to use [kitchen-salt](https://github.com/saltstack/kitchen-salt), the Kitchen plugin that provides Salt provisioner

Following directory contains setup of kitchen test **runner** (`Vagrantfile` for the test executor).  
Basically it spawns LXC container (using Vagrant) and provisions it using ambassador (create your own pillar configuration)

Prepare `kitchen.local.yml`
```
platforms:
  - name: debian
    lifecycle:
      pre_converge:
        - remote: 'echo "deb http://ftp.debian.org/debian stretch-backports main" | sudo tee /etc/apt/sources.list.d/backports.list'
        - remote: 'sudo apt-get update'
        - remote: 'sudo apt-get upgrade -y -o DPkg::Options::=--force-confold'
        - remote: 'sudo apt-get install -y ca-certificates wget host curl gnupg2 sudo apt-transport-https libffi-dev git python3-pip zlib1g-dev'
        - remote: 'sudo apt-get install -t stretch-backports -y libgit2-dev'
        - remote: 'sudo pip3 install --upgrade pyOpenSSL pygit2==0.27.3 docker-py cherrypy jinja2 Flask eventlet PyYAML flask-socketio requests_oauthlib google-auth'
    driver:
      box: "debian/stretch64"      
      customize:
        host: maybe_remote
        username: coolguy
        connect_via_ssh: true
        id_ssh_key_file: /home/vagrant/.ssh/id_rsa
        uri: "qemu+ssh://coolguy@maybe_remote/system"
      ssh:
        insert_key: false
    driver_config:
      run_command: /lib/systemd/systemd
suites:
  - name: default
    provisioner:
      pillars:
        top.sls:
          base:
            '*':
              - overrides
        overrides.sls:
          some:
            extra:
              pillar: "to add"
```
Prepare `.local/pillar.conf` for VM under-test (salt minion configuration)

To run tests add `.test/runner.sh` to `cron` (ideally using Ambassador)
