# -*- mode: ruby -*-
# vi: set ft=ruby :

common_vagrantfile = File.expand_path('../Vagrantfile.common', __FILE__)
load common_vagrantfile if File.exists?(common_vagrantfile)

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.hostname = ENV['CONTAINER_FQDN']

  config.vm.define ENV['CONTAINER_NAME'] do |node|
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine
      lxc.backingstore = 'best'
      lxc.fetch_ip_tries = 30
      lxc.customize 'start.auto', ENV['AMBASSADOR_AUTO_START']
    end
  end

  if ENV.has_key?('DEPLOY_PUB_FILE') and ENV.has_key?('DEPLOY_PRIV_FILE')
    config.vm.provision "file", source: ENV['DEPLOY_PUB_FILE'], destination: "deploykeys/cfg_ro.key.pub"
    config.vm.provision "file", source: ENV['DEPLOY_PRIV_FILE'], destination: "deploykeys/cfg_ro.key"
  end

  if ENV.has_key?('PILLAR_GPG_PUB_FILE') and ENV.has_key?('PILLAR_GPG_PRIV_FILE')
    config.vm.provision "file", source: ENV['PILLAR_GPG_PUB_FILE'], destination: "pillargpg/pillar.gpg.pub"
    config.vm.provision "file", source: ENV['PILLAR_GPG_PRIV_FILE'], destination: "pillargpg/pillar.gpg"
  end

  if ENV.has_key?('AMBASSADOR_KDBX')
    config.vm.provision "file", source: ENV['AMBASSADOR_KDBX'], destination: "ambassador.kdbx"
  end

  if ENV.has_key?('AMBASSADOR_KDBX_KEY')
    config.vm.provision "file", source: ENV['AMBASSADOR_KDBX_KEY'], destination: "ambassador.key"
  end

  config.vm.synced_folder "extensions/file_ext_authorize", "/opt/file_ext_authorize"
  config.vm.synced_folder "salt", "/srv/salt"

  config.vm.provision "install salt requisites", type: "shell" do |s|
    s.path = "https://gist.githubusercontent.com/kiemlicz/1aa8c2840f873b10ecd744bf54dcd018/raw/e0985c4e8f9bf5c66923a1fb22b2df197504b3ea/setup_salt_requisites.sh"
  end

  config.vm.provision "salt configuration", type: "shell", env: {
    "PILLAR_GPG_PUB_FILE" => ENV['PILLAR_GPG_PUB_FILE'],
    "PILLAR_GPG_PRIV_FILE" => ENV['PILLAR_GPG_PRIV_FILE']
  } do |s|
    s.inline = <<-SHELL
        sudo cat << EOF > /srv/salt/base/top.sls
server:
  'ambassador*':
    - os
    - users
    - salt.master
    - salt.api
    - salt.ssh
    - foreman
EOF
      gpg --homedir /etc/salt/gpgkeys --import /home/vagrant/pillargpg/pillar.gpg
    SHELL
  end

  if File.file?("ambassador-installer.override.conf")
    config.vm.provision "file", source: "ambassador-installer.override.conf", destination: "ambassador-installer.override.conf"
  else
    config.vm.provision "fail", type: "shell" do |s|
      s.inline = <<-SHELL
          >&2 echo "ambassador-installer.override.conf was not found in project root dir, create this file"
          exit 3
      SHELL
    end
  end

  config.vm.provision :salt do |salt|
    salt.masterless = true
    salt.minion_config = "config/ambassador-installer.conf"
    salt.run_highstate = true
    salt.bootstrap_options = "-x python3"
  end
end
