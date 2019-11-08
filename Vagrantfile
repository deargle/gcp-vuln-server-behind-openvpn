# -*- mode: ruby -*-
# vi: set ft=ruby :


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # Vagrant::DEFAULT_SERVER_URL.replace('https://vagrantcloud.com')
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  
  config.vm.define "gcp" do |gcp|
    gcp.vm.box = 'google/gce'
    gcp.vm.box_version = "0.1.0"
    
    gcp.vm.provider :google do |google, override|
      google.google_project_id = "midterm-vuln"
      google.name = 'midterm-vuln'
      google.google_json_key_location = "midterm-vuln-gcp-private-key.json"
      
      # google.external_ip = true
      google.image_family = 'ubuntu-1404-lts'
      # vagrant@terraform-255421.iam.gserviceaccount.com
      override.ssh.username = "_provisioner"
      override.ssh.private_key_path = "tyler-midterm-vuln"
    end
  end
  

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false
  # config.vm.synced_folder '.', '/vagrant', disabled: true
  
  config.vm.provision "chef_solo" do |chef|
    chef.arguments = '--chef-license accept'
    chef.cookbooks_path = ['cookbooks','berks-cookbooks']
    run_list = File.read('chef_runlist')
  end

end
