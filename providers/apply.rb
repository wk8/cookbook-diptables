def whyrun_supported?
  # only platform resources below, nothing to do to enforce that
  true
end

# see https://docs.chef.io/lwrp_custom_provider.html#use-inline-resources
use_inline_resources

action :apply do
  template 'diptables-rules-file' do
    path node['diptables']['rules_path']
    source 'iptables_rules.erb'
    cookbook 'diptables'
  end

  if node['diptables']['dry_run']
    Chef::Log.warn("Running diptables::default cookbook in dry_run mode, your iptables configuration won't be changed!")
  else
    iptables_restore_command = "iptables-restore < #{node['diptables']['rules_path']}"

    execute 'diptables-reload-iptables' do
      command iptables_restore_command
      user 'root'
      action :nothing
      subscribes :run, 'template[diptables-rules-file]', :immediately
    end

    # only mark as updated if the rules did change
    apply_resource = self.new_resource
    ruby_block "mark diptables_apply #{apply_resource} as updated" do
      block { apply_resource.updated_by_last_action true }
      action :nothing
      subscribes :run, 'template[diptables-rules-file]'
    end

    # set iptables to autolad
    case node['platform_family']
    when 'debian'
      file '/etc/network/if-up.d/iptables-rules' do
        owner 'root'
        group 'root'
        mode '0744'
        content "#!/bin/sh\n#{iptables_restore_command}\n"
        action :create
      end
    when 'rhel'
      execute 'iptables autoload' do
        command 'service iptables save'
        # if we already write to '/etc/sysconfig/iptables', no need to save
        not_if { node['diptables']['rules_path'] == '/etc/sysconfig/iptables' }
      end
    else
      Chef::Log.warn("Don't know how to set up automatic iptables on your distribution, sorry. Please submit a bug ticket at https://github.com/wk8/cookbook-iptables/issues")
    end
  end

  ruby_block 'diptables_config_applied' do
    block do
      node.run_state[:diptables_config_applied] = true
      node.run_state[:diptables_config_last_applied_by] = new_resource
    end
  end
end
