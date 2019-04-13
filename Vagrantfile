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
    end
  end

  if ENV.has_key?("CLIENT_ID") and ENV.has_key?("CLIENT_SECRET")
    # todo what is the visibility scope, is it like in bash?
    ambassador_client_id = ENV["CLIENT_ID"]
    ambassador_client_secret = ENV["CLIENT_SECRET"]
  end

  ambassador_cert_base = ENV['CONTAINER_CERT_BASE']
  ambassador_ca = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['CA_CERT_FILE']))
  ambassador_crl = File.join(ENV['CONTAINER_CERT_BASE'], File.basename(ENV['CRL_FILE']))
  ambassador_key = File.join(ENV['CONTAINER_PRIVATE_DIR'], File.basename(ENV['SERVER_KEY_FILE']))
  ambassador_proxy_key = File.join(ENV['CONTAINER_PRIVATE_DIR'], File.basename(ENV['SERVER_PROXY_KEY_FILE']))
  ambassador_cert = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['SERVER_CERT_FILE']))
  ambassador_proxy_cert = File.join(ENV['CONTAINER_CERT_DIR'], File.basename(ENV['SERVER_PROXY_CERT_FILE']))
  ambassador_gw = `ip route show`[/default.*/][/\d+\.\d+\.\d+\.\d+/]
  ambassador_salt_api_port = "9191"
  ambassador_salt_api_interfaces = "0.0.0.0"
  ambassador_salt_user = "saltuser"
  ambassador_salt_password = "saltpassword"
  ambassador_fqdn = ENV['CONTAINER_FQDN']
  ambassador_tftp_root = ENV['TFTP_ROOT']
  ambassador_domain = `dnsdomainname`

  if ENV.has_key?('DEPLOY_PUB_FILE') and ENV.has_key?('DEPLOY_PRIV_FILE')
    # todo what is the visibility scope, is it like in bash?
    ambassador_envoy_deploy_pub = File.basename(ENV['DEPLOY_PUB_FILE'])
    ambassador_envoy_deploy_priv = File.basename(ENV['DEPLOY_PRIV_FILE'])
    # todo the ambassador_gitfs_deploykeys.conf will contain bogus paths if DEPLOY_PUB/PRIV_FILE is not defined
    config.vm.provision "file", source: ENV['DEPLOY_PUB_FILE'], destination: File.join("etc/salt/deploykeys/", ambassador_envoy_deploy_pub)
    config.vm.provision "file", source: ENV['DEPLOY_PRIV_FILE'], destination: File.join("etc/salt/deploykeys/", ambassador_envoy_deploy_priv)
  end

  materialize_recursively("config/guest", ".target", binding)

  config.vm.provision "file", source: ".target", destination: "~/target"
  config.vm.provision "file", source: "salt", destination: "~/srv/salt"
  config.vm.provision "file", source: "extensions/file_ext_authorize", destination: "~/opt/file_ext_authorize"

  config.vm.provision "move config", type: "shell" do |s|
    s.inline = <<-SHELL
         sudo rsync -avzh target/* /
    SHELL
  end
end

vagrantfiles = %w[../Vagrantfile.foreman ../Vagrantfile.salt]
vagrantfiles.each do |vagrantfile|
  load File.expand_path(vagrantfile) if File.exists?(vagrantfile)
end
