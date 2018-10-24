# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'
require 'erb'
require 'fileutils'

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"
  config.vm.hostname = ENV['CONTAINER_FQDN']

  config.vm.define ENV['CONTAINER_NAME'] do |node|
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine
      lxc.backingstore = 'best'
    end
  end

  def materialize(render, filename)
    FileUtils.mkdir_p(File.dirname(filename))
    File.open(filename, "w") do |f|
      f.write render
    end
  end

  config.vm.provision "init", type: "shell", env: {
    "CONTAINER_USERNAME" => ENV['CONTAINER_USERNAME'],
    "CONTAINER_NAME" => ENV['CONTAINER_NAME'],
    "CONTAINER_FQDN" => ENV['CONTAINER_FQDN']
    } do |s|
    s.inline = <<-SHELL
        sudo apt-get update
        sudo apt-get install -y rsync
        sudo mkdir -p /etc/sudoers.d/
        echo 'Cmnd_Alias SALT = /usr/bin/salt, /usr/bin/salt-key\nforeman-proxy ALL = NOPASSWD: SALT\nDefaults:foreman-proxy !requiretty' > /etc/sudoers.d/salt; chmod 440 /etc/sudoers.d/salt

        if [ "$CONTAINER_USERNAME" != "root" ]; then
            echo 'ubuntu ALL=NOPASSWD:ALL' > /etc/sudoers.d/ubuntu; chmod 440 /etc/sudoers.d/ubuntu
        fi

        #todo how to achieve passwordless sudo -u postgres, below doesn't work
        #echo 'postgres ALL=NOPASSWD:ALL' > /etc/sudoers.d/postgres; chmod 440 /etc/sudoers.d/postgres

        # remove accepting locale on server so that no locale generation is needed
        sed -i -e 's/\(^AcceptEnv LANG.*\)/#\1/g' /etc/ssh/sshd_config
        CIP=$(ip r s | grep "scope link src" | cut -d' ' -f9)
        sed -i "s/127.0.1.1/#127.0.1.1/" /etc/hosts
        echo "$CIP  $CONTAINER_FQDN $CONTAINER_NAME" >> /etc/hosts
        #configure resolvconf utility so that proper nameserver exists, otherwise only 127.0.0.1 may appear
        echo 'TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=no' > /etc/default/resolvconf
    SHELL
  end

  if ENV.has_key?("CLIENT_ID") and ENV.has_key?("CLIENT_SECRET")
    ambassador_client_id = ENV["CLIENT_ID"]
    ambassador_client_secret = ENV["CLIENT_SECRET"]
  end
  ambassador_ca = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['CA_CERT_FILE']))
  ambassador_crl = File.join(ENV['CONTAINER_CERT_BASE'], File.basename(ENV['CRL_FILE']))
  ambassador_key = File.join(ENV['CONTAINER_PRIVATE_DIR'], File.basename(ENV['SERVER_KEY_FILE']))
  ambassador_proxy_key = File.join(ENV['CONTAINER_PRIVATE_DIR'], File.basename(ENV['SERVER_PROXY_KEY_FILE']))
  ambassador_cert = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['SERVER_CERT_FILE']))
  ambassador_proxy_cert = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['SERVER_PROXY_CERT_FILE']))
  ambassador_gw = `ip route show`[/default.*/][/\d+\.\d+\.\d+\.\d+/]
  ambassador_salt_api_port = "9191"
  ambassador_salt_api_interfaces = "0.0.0.0"
  ambassador_fqdn = ENV['CONTAINER_FQDN']

  if ENV.has_key?('DEPLOY_PUB_FILE') and ENV.has_key?('DEPLOY_PRIV_FILE')
       # todo what is the visibility scope, is it like in bash?
    ambassador_envoy_deploy_pub = File.basename(ENV['DEPLOY_PUB_FILE'])
    ambassador_envoy_deploy_priv = File.basename(ENV['DEPLOY_PRIV_FILE'])

    materialize(ERB.new(File.read("config/salt/ambassador_gitfs_deploykeys.erb")).result(binding), "etc/salt/master.d/ambassador_gitfs_deploykeys.conf")

    config.vm.provision "file", source: ENV['DEPLOY_PUB_FILE'], destination: File.join("etc/salt/deploykeys/", ambassador_envoy_deploy_pub)
    config.vm.provision "file", source: ENV['DEPLOY_PRIV_FILE'], destination: File.join("etc/salt/deploykeys/", ambassador_envoy_deploy_priv)
  end

  if ENV['USE_ROOTS'] == "true"
    materialize(ERB.new(File.read("config/salt/ambassador_roots.erb")).result(binding), "etc/salt/master.d/ambassador_roots.conf")
  else
    materialize(ERB.new(File.read("config/salt/ambassador_gitfs.erb")).result(binding), "etc/salt/master.d/ambassador_gitfs.conf")
  end
  materialize(ERB.new(File.read("config/salt/ambassador_common.erb")).result(binding), "etc/salt/master.d/ambassador_common.conf")
  materialize(ERB.new(File.read("config/salt/ambassador_ext_pillar.erb")).result(binding), "etc/salt/master.d/ambassador_ext_pillar.conf")
  materialize(ERB.new(File.read("config/salt/ambassador_salt_foreman.erb")).result(binding), "etc/salt/master.d/ambassador_salt_foreman.conf")
  materialize(ERB.new(File.read("config/salt/reactor.erb")).result(binding), "etc/salt/master.d/reactor.conf")
  materialize(ERB.new(File.read("config/salt/foreman.erb")).result(binding), "etc/salt/foreman.yaml")
  materialize(ERB.new(File.read("config/foreman/salt.erb")).result(binding), "etc/foreman-proxy/settings.d/salt.yml")
  materialize(ERB.new(File.read("config/proxydhcp.erb")).result(binding), "etc/dnsmasq.d/proxydhcp.conf")

  #apache2 during installation removes contents of /etc/apache2/sites-available/
  materialize(ERB.new(File.read("config/apache2/30-saltfs.erb")).result(binding), "var/tmp/30-saltfs.conf")

  config.vm.provision "file", source: "etc", destination: "~/etc"
  config.vm.provision "file", source: "var", destination: "~/var"
  config.vm.provision "file", source: "config/file_ext_authorize.service", destination: "~/etc/systemd/system/file_ext_authorize.service"
  config.vm.provision "file", source: "config/bootloader", destination: "~/var/lib/tftpboot"
  config.vm.provision "file", source: "envoy/extensions/pillar", destination: "~/srv/salt_ext/pillar"
  config.vm.provision "file", source: "envoy/salt", destination: "~/srv/salt"
  config.vm.provision "file", source: "envoy/pillar", destination: "~/srv/pillar"
  config.vm.provision "file", source: "envoy/reactor", destination: "~/srv/reactor"
  config.vm.provision "file", source: "extensions/file_ext_authorize", destination: "~/opt/file_ext_authorize"
  config.vm.provision "file", source: "config/file_ext_authorize.conf", destination: "~/opt/file_ext_authorize/file_ext_authorize.conf"

  config.vm.provision "move config", type: "shell" do |s|
    s.inline = <<-SHELL
         sudo rsync -avzh etc/ /etc
         sudo rsync -avzh opt/ /opt
         sudo rsync -avzh var/ /var
         sudo rsync -avzh srv/ /srv
    SHELL
  end

  CSV.parse_line(ENV['USERS']).each do |u|
    config.vm.provision "#{u} key", type: "shell", env: {"CONTAINER_USERNAME" => ENV['CONTAINER_USERNAME']} do |s|
        ssh_pub_key = File.readlines("#{Dir.home(u)}/.ssh/id_rsa.pub").first.strip
        s.inline = <<-SHELL
            user_dir=$(eval echo "~$CONTAINER_USERNAME")
            mkdir -p $user_dir/.ssh/
            echo #{ssh_pub_key} >> $user_dir/.ssh/authorized_keys
            #todo  verify permissions of authorized_keys
        SHELL
    end
  end

  config.vm.provision "install", type: "shell" do |s|
    s.path = "setup_salt.sh"
  end

  config.vm.provision "install", type: "shell", env: {
    "CID" => ENV['CONTAINER_FQDN'],
    "CERT_BASEDIR" => ENV['CONTAINER_CERT_BASE'],
    "CA" => ambassador_ca,
    "CRL" => ambassador_crl,
    "KEY" => ambassador_key,
    "PROXY_KEY" => ambassador_key,
    "CERT" => ambassador_cert,
    "PROXY_CERT" => ambassador_cert
    } do |s|
    s.path = "setup_foreman.sh"
  end

end
