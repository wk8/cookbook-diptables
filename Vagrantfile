# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = '2'

Vagrant.require_version '>= 1.5.0'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.hostname = 'diptables-vagrant'
  config.omnibus.chef_version = '12.0.1'
  config.vm.box = 'chef/ubuntu-14.04'

  config.berkshelf.enabled = true

  config.vm.provision :chef_solo do |chef|
    # uncomment if you want a verbose run
    # chef.log_level = 'debug'

    chef.json = {
      'diptables_tests' => {
        'cookbook_root' => '/vagrant'
      }
    }

    chef.run_list = [
      'chef-dk',
      'recipe[diptables_tests::chef_dk_profile]',
      'recipe[diptables_tests::run_rspec]',
      'recipe[diptables_tests::full_example]'
    ]
  end
end
