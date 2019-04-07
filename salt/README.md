[![Build status](https://travis-ci.org/kiemlicz/envoy.svg?branch=master)](https://travis-ci.org/kiemlicz/envoy)
# Basics 
[Salt](https://saltstack.com/) _states_ for provisioning machines in generic yet sensible way.  
The goal is to create _salt environments_ usable by developers as well as admins during the setup of either server or 'client' machines.

## Setup  
There are multiple options to deploy **envoy**.  
They depend on how you want to provision machines:  
 1. Separate `salt-master` process provisioning `salt-minions`:  
Refer to SaltStack documentation of [gitfs](https://docs.saltstack.com/en/latest/topics/tutorials/gitfs.html) 
(if you prefer local filesystem then familiarize with [multienv](https://docs.saltstack.com/en/latest/ref/states/top.html)) or use 
fully automated setup of SaltStack via associated [project ambassador](https://github.com/kiemlicz/ambassador)

 2. Master-less provisioning (machine provisions itself):  
 **Steps**  
    1. `curl -o /tmp/bootstrap-salt.sh -L https://bootstrap.saltstack.com`, requires (`apt-get install curl python-pip python-pygit2`)
    2. `sh /tmp/bootstrap-salt.sh -X`
    3. Create masterless configs: `config/common.conf` and `config/gitfs.conf` (put under `/etc/salt/minion.d/`), use associated [project ambassador](https://github.com/kiemlicz/ambassador) for guidelines how to create such configs
    4. `systemctl start salt-minion`  
    5. Optionally run `salt-call --local saltutil.sync_all`
 
It is possible to use both methods, e.g., initially provision the machine using master-minion setup, "unplug" the minion and use master-less when needed.  
 
### Using as Vagrant provisioner
Vagrant supports [_Salt_ provisioner](https://www.vagrantup.com/docs/provisioning/salt.html)

  1. Add following sections to `Vagrantfile`.
```
    Vagrant.configure("2") do |config|
    ...
        config.vm.synced_folder "/srv/salt/", "/srv/salt/"  # add states from host
    
        config.vm.provision "init", type: "shell" do |s|
          s.path = "https://gist.githubusercontent.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a/raw/b9aba40aa30f238a24fe4ecb4ddc1650d9d685af/init.sh"
        end
    
        config.vm.provision :salt do |salt|
          salt.masterless = true
          salt.minion_config = "minion.conf"
          salt.run_highstate = true
          salt.salt_args = [ "saltenv=server" ]
        end
    ...
    end
```

`init.sh`: bash [script](https://gist.github.com/kiemlicz/33e891dd78e985bd080b85afa24f5d0a) that installs salt requisites, e.g., git, pip packages (jinja2) etc.  
`minion.conf`: configure `file_client: local` and whatever you like (mutlienvs, gitfs, ext_pillar)
  
  2. `vagrant up`

### Using Kubernetes
Depending on use case, different deployment strategies exist.

#### Using envoy to deploy Kubernetes
_Salt Master_ installed on separate machine, _Salt Minion_ installed on each [Kubernetes node](https://kubernetes.io/docs/concepts/architecture/nodes/).

This way it is possible to automatically create Kubernetes master and worker nodes

For documentation refer to [Kubernetes states](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#kubernetes)

#### Using envoy to provision in-Kubernetes pods
In this strategy the _Salt Master_ is deployed within dedicated pod and _Salt Minions_ are deployed as [DaemonSet](https://kubernetes.io/docs/concepts/workloads/controllers/daemonset/).  
In this approach, the _Salt Minion_ is **not** the provisioned entity. 
Instead the _Salt Minion_ registers [`docker_events` engine](https://docs.saltstack.com/en/latest/ref/engines/all/salt.engines.docker_events.html). The engine captures 
docker host events and forwards them to _Salt Master Event Bus_. [_Salt Master's Reactor System_](https://github.com/kiemlicz/util/wiki/Salt-Events-and-Reactor) is then used to
add additional provisioning logic that is impossible (not in an easy way at least) to provide using Kubernetes tools only.  
Example: creating and maintaining Redis Cluster.

Mind that _Salt Minion_ is **not** installed on every container and **not** used to fully configure that container. That would be possible but
this should be the responsibility of the tool that is used to create that container (of course it is possible to use _Salt_ as such tool)

More detailed description can be found in [POD provisioning section](https://github.com/kiemlicz/envoy/tree/master/salt/server/kubernetes#provisioning-pods) 
    
## Components
In order to run _states_ against _minions_, _pillar_ must be configured.  
Refer to `pillar.example.sls` files in states themselves for particular structure.  
_States_ must be written with assumption that given pillar entry may not exist.
For detailed state description, refer to particular states' README file.
 
# Structure
States are divided in environments:
 1. `base` - the main one. Any other environment comprises of at least `base`. Contains core states responsible for operations like
 repositories configuration, core packages installation or user setup
 2. `dev` - for developer machines. Includes `base`. Contains states that install tons of dev apps along with their configuration (like add entry to `PATH` variable)
 3. `server` - installs/configured typical server tools, e.g., Kubernetes or LVS. Includes `base` and `dev`

# Extensions
In order to keep _states_ readable and configuration of whole SaltStack as flexible as possible, some extensions and custom states were introduced.

All of the custom states can be found in default _Salt_ extensions' [directories](https://docs.saltstack.com/en/latest/ref/file_server/dynamic-modules.html) (`_pillar`, `_runner`, etc.)

## Custom Pillars
### privgit
Dynamically configured git pillar.  
Allows users to configure their own _pillar_ data git repository in the runtime - using pillar entries.
Normally `git_pillar` must be configured in the _Salt Master_ configuration beforehand.

#### Usage
Append `privgit` to `ext_pillar` configuration option to enable this extension.  
The syntax:
```
ext_pillar:                # Salt option
  - privgit:               # extension name
    - name1:               # first entry identifier
        param1:            # the parameters dict
        param2:            # append in config only the options that most likely won't be changed by users
```
Fully static configuration (use _git_pillar_ instead of such):
```
ext_pillar:
  - privgit:
    - name1:
        url: git@github.com:someone/somerepo.git
        branch: master  
        env: custom
        root: pillar
        privkey: |
        some
        sensitive data
        pubkey: and so on
    - name2:
        url: git@github.com:someone/somerepo.git
        branch: develop
        env: custom
        privkey_location: /location/on/master
        pubkey_location: /location/on/master
```
Parameters are formed as a list, next entries override previous:  
```
privgit:
  - name1:
        url: git@github.com:someone/somerepo.git
        branch: master  
        env: custom
        root: pillar
        privkey: |
        some
        sensitive data
        pubkey: and so on
  - name2:
        url: git@github.com:someone/somerepo.git
        branch: develop
        env: custom
        privkey_location: /location/on/master
        pubkey_location: /location/on/master
  - name2:
        url: git@github.com:someone/somerepo.git
        branch: notdevelop
```
Entries order does matter, last one is the most specific one. It doesn't affect further pillar merge strategies.

Due to potential integration with systems like [foreman](https://theforeman.org/) that support string keys only, 
another (unpleasant, flat) syntax exists:
```
privgit_name1_url: git@github.com:someone/somerepo.git
privgit_name1_branch: master 
privgit_name1_env: custom
privgit_name1_root: pillar
privgit_name1_privkey: |
        some
        sensitive data
privgit_name1_pubkey: and so on
privgit_name2_url: git@github.com:someone/somerepo.git
privgit_name2_branch: develop
privgit_name2_env: custom
privgit_name2_privkey_location: /location/on/master
privgit_name2_pubkey_location: /location/on/master
```

### kubectl
Pulls any Kubernetes information and adds them to pillar.  
It is possible to specify pillar key under which the Kubernetes data will be hooked up.  
Under the hood this extension executes:
`kubectl get -o yaml -n <namespace or deafult> <kind> <name>` or 
`kubectl get -o yaml -n <namespace or deafult> <kind> -l <selector>` if name is not provided

There is no (not yet) per-minion filtering of Kubernetes pillar data, thus this data will be matched to all minions.  
For Kubernetes deployments (minions as daemon set) this should be acceptable.
 
#### Usage
```
ext_pillar:
  - kubectl:
      config: "/some/path/to/kubernetes/access.conf"   # all queries will use this config
      queries:
        - kind: statefulsets
          name: redis-cluster
          key: "redis:kubernetes"                      # nest the results under `redis:kubernetes` 
``` 
## Custom States
### dotfile
Custom _state_ that manages [dotfiles](https://en.wikipedia.org/wiki/Dot-file).  
Clones them from passed repository and sets up according to following [technique](https://developer.atlassian.com/blog/2016/02/best-way-to-store-dotfiles-git-bare-repo/)

### devtool
Most dev tools setup comes down to downloading some kind of archive, unpacking it and possibly adding symlink to some generic location.  
This state does pretty much that.

### envops
Environment variables operations.

## Custom Execution Modules
 
# Tests
Tests are performed on different OSes (in docker) in _Salt_ masterless mode.  
Different [pillar data](https://github.com/kiemlicz/envoy/tree/master/.travis/pillar) is mixed with different [saltenvs](https://github.com/kiemlicz/envoy/tree/master/salt).  
Then the `salt-call --local state.show_sls <state name>` is invoked and checked if renders properly

More complex tests that perform actual state application in different environments are performed in associated [ambassador project](https://github.com/kiemlicz/ambassador)
 
# References
1. SaltStack [quickstart](https://docs.saltstack.com/en/latest/topics/states/index.html)
2. SaltStack [best practices](https://docs.saltstack.com/en/latest/topics/best_practices.html)
