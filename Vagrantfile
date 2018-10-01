# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'
require 'erb'

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"

  config.vm.define ENV['CONTAINER_NAME'] do |node|
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine
      lxc.backingstore = 'best'
    end
  end

  config.vm.provision "init", type: "shell", env: {
    "CONTAINER_USERNAME" => ENV['CONTAINER_USERNAME'],
    "CONTAINER_NAME" => ENV['CONTAINER_NAME'],
    "CONTAINER_FQDN" => ENV['CONTAINER_FQDN']
    } do |s|
    s.inline = <<-SHELL
        mkdir -p /etc/sudoers.d/
        echo 'Cmnd_Alias SALT = /usr/bin/salt, /usr/bin/salt-key\nforeman-proxy ALL = NOPASSWD: SALT\nDefaults:foreman-proxy !requiretty' > /etc/sudoers.d/salt; chmod 440 /etc/sudoers.d/salt

        if [ "$CONTAINER_USERNAME" != "root" ]; then
            echo 'ubuntu ALL=NOPASSWD:ALL' > /etc/sudoers.d/ubuntu; chmod 440 /etc/sudoers.d/ubuntu
        fi

        #todo how to achieve passwordless sudo -u postgres, below doesn't work
        #echo 'postgres ALL=NOPASSWD:ALL' > /etc/sudoers.d/postgres; chmod 440 /etc/sudoers.d/postgres

        # remove accepting locale on server so that no locale generation is needed
        sed -i -e 's/\(^AcceptEnv LANG.*\)/#\1/g' /etc/ssh/sshd_config
        sed -i "/^127.0.1.1 /s/$CONTAINER_NAME/$CONTAINER_FQDN $CONTAINER_NAME/" /etc/hosts

        #configure resolvconf utility so that proper nameserver exists, otherwise only 127.0.0.1 may appear
        echo 'TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=no' > /etc/default/resolvconf

        mkdir -p /etc/salt/deploykeys/
        mkdir -p /etc/salt/master.d/
        mkdir -p /etc/salt/cloud.providers.d/
        mkdir -p /etc/salt/cloud.profiles.d/
        mkdir -p /etc/foreman-proxy/settings.d/
        mkdir -p /etc/dnsmasq.d/
        mkdir -p /srv/salt_ext/
        mkdir -p /var/lib/tftpboot/
        mkdir -p /etc/apache2/sites-available/
    SHELL
  end

  # todo check if destination is auto-created, if so move to top and remove above mkdir -p
  config.vm.provision "file", source: ENV['CA_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_PROXY_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_KEY_FILE'], destination: ENV['CONTAINER_PRIVATE_DIR']
  config.vm.provision "file", source: ENV['SERVER_PROXY_KEY_FILE'], destination: ENV['CONTAINER_PRIVATE_DIR']
  config.vm.provision "file", source: ENV['CRL_FILE'], destination: ENV['CONTAINER_CERT_BASE']
  config.vm.provision "file", source: "envoy/extensions/pillar", destination: "/srv/salt_ext/pillar"
  config.vm.provision "file", source: "config/bootloader", destination: "/var/lib/tftpboot"
  config.vm.provision "file", source: "extensions/file_ext_authorize", destination: "/opt/file_ext_authorize"
  config.vm.provision "file", source: "config/file_ext_authorize.service", destination: "/etc/systemd/system"
  config.vm.provision "file", source: "envoy/salt", destination: "/srv/salt"
  config.vm.provision "file", source: "envoy/pillar", destination: "/srv/pillar"
  config.vm.provision "file", source: "envoy/reactor", destination: "/srv/reactor"

  if File.file?(ENV['DEPLOY_PUB_FILE']) and File.file?(ENV['DEPLOY_PRIV_FILE'])
    # todo what is the visibility scope, is it like in bash?
    ambassador_envoy_deploy_pub = File.basename(ENV['DEPLOY_PUB_FILE'])
    ambassador_envoy_deploy_priv = File.basename(ENV['DEPLOY_PRIV_FILE'])

    config.vm.provision "file", source: ENV['DEPLOY_PUB_FILE'], destination: /etc/salt/deploykeys/
    config.vm.provision "file", source: ENV['DEPLOY_PRIV_FILE'], destination: /etc/salt/deploykeys/
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
  ambassador_salt_api_port = 9191
  ambassador_salt_api_interfaces = 0.0.0.0
  ambassador_fqdn = ENV['CONTAINER_FQDN']

  #todo read all configs (change variable patterns to ERB-style) and render them to guest
  template = ERB.new File.read("config/ambassador_roots.conf")

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



end
