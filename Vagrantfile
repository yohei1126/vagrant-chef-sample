# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.omnibus.chef_version=:latest
  config.chef_zero.chef_repo_path = "."
  #config.berkshelf.enabled=true
  #config.vm.network :private_network, ip: "192.168.1.2"

  config.vm.box = "centos7"
  config.vm.box_url = "https://f0fff3908f081cb6461b407be80daf97f07ac418.googledrive.com/host/0BwtuV7VyVTSkUG1PM3pCeDJ4dVE/centos7.box"
  config.vm.provision :chef_client do |chef|
    chef.custom_config_path = "chef_custom_config"
    chef.run_list = []
    #    "playframework"
    #]
  end
end
