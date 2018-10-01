# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'csv'

Vagrant.configure("2") do |config|
  config.vm.box = "debian/stretch64"

  config.vm.define ENV['CONTAINER_NAME'] do |node|
    node.vm.provider :lxc do |lxc|
      lxc.container_name = :machine
      lxc.backingstore = 'best'
    end
  end


  config.vm.provision "file", source: ENV['CA_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_PROXY_CERT_FILE'], destination: ENV['CONTAINER_CERT_DIR']
  config.vm.provision "file", source: ENV['SERVER_KEY_FILE'], destination: ENV['CONTAINER_PRIVATE_DIR']
  config.vm.provision "file", source: ENV['SERVER_PROXY_KEY_FILE'], destination: ENV['CONTAINER_PRIVATE_DIR']
  config.vm.provision "file", source: ENV['CRL_FILE'], destination: ENV['CONTAINER_CERT_BASE']

  config.vm.provision "init", type: "shell" do |s|
    s.args = [ENV['CONTAINER_NAME'], ENV['CONTAINER_FQDN']]
    s.inline = <<-SHELL

        mkdir -p /etc/sudoers.d/
        echo 'Cmnd_Alias SALT = /usr/bin/salt, /usr/bin/salt-key\nforeman-proxy ALL = NOPASSWD: SALT\nDefaults:foreman-proxy !requiretty' > /etc/sudoers.d/salt; chmod 440 /etc/sudoers.d/salt

        #todo how to achieve passwordless sudo -u postgres, below doesn't work
        #echo 'postgres ALL=NOPASSWD:ALL' > /etc/sudoers.d/postgres; chmod 440 /etc/sudoers.d/postgres

        # remove accepting locale on server so that no locale generation is needed
        sed -i -e 's/\(^AcceptEnv LANG.*\)/#\1/g' /etc/ssh/sshd_config
        sed -i "/^127.0.1.1 /s/$1/$2 $1/" /etc/hosts

        #configure resolvconf utility so that proper nameserver exists, otherwise only 127.0.0.1 may appear
        echo 'TRUNCATE_NAMESERVER_LIST_AFTER_LOOPBACK_ADDRESS=no' > /etc/default/resolvconf
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

  config.vm.provision "login", type: "shell", env: {"CONTAINER_USERNAME" => ENV['CONTAINER_USERNAME']} do |s|
    s.inline = <<-SHELL
        if [ "$CONTAINER_USERNAME" != "root" ]; then
            echo 'ubuntu ALL=NOPASSWD:ALL' > /etc/sudoers.d/ubuntu; chmod 440 /etc/sudoers.d/ubuntu
        fi
    SHELL
  end

end
