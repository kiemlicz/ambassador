# Self-hosted test environment
Due to numerous docker limitations tests should be performed in LXC container or even better: dedicated VMs

The most common way is to use [kitchen-salt](https://github.com/saltstack/kitchen-salt), the Kitchen plugin that provides Salt provisioner

Following directory contains setup of kitchen test **runner** (the machine that will be running tests).  
Basically it spawns LXC container (using Vagrant) and provisions it using Ambassador (create your own pillar configuration)

Prepare `kitchen.local.yml` (it's possible to automate the creation using Ambassador)
```
platforms:
  - name: debian9
    lifecycle:
      pre_converge:
        - remote: 'sudo su -c "bash <(wget --no-check-certificate -qO- https://gist.githubusercontent.com/kiemlicz/1aa8c2840f873b10ecd744bf54dcd018/raw/9bc130ba6800b1df66a3e34901d0c18dca560fd4/setup_salt_requisites.sh)"'
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
      salt_minion_extra_config:
        # the tested VM minion config options like:
        custom_sdb:
           driver: custom_sdb
        ext_pillar: []
        gitfs_remotes: {}
        # in general: minion config that will be merged with minion.erb
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

Prepare `minion-zeus.override.conf` for any runner minion config overrides, like:
```
kdbx:
  driver: kdbx
  db_file: /the/keepass/file/keepass.kdbx
  password: pass
  key_file: /the/key/file/keepass.key

```

To run tests add `.test/runner.sh` to `cron`
