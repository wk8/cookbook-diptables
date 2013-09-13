# Cookbook Name:: diptables
# Recipe:: default

unless node['diptables']['dry_run']
    execute 'reload-iptables' do
        command "iptables-restore < #{node['diptables']['rules_path']}"
        user 'root'
        action :nothing
    end
end

template node['diptables']['rules_path'] do
    source 'iptables_rules.erb'
    notifies :run, 'execute[reload-iptables]' unless node['diptables']['dry_run']
    action :create
end

unless node['diptables']['dry_run']
    # set iptables to autolad
    case node['platform_family']
    when 'debian'
      # TODO: generalize this for other platforms somehow
        file '/etc/network/if-up.d/iptables-rules' do
            owner 'root'
            group 'root'
            mode '0755'
            content "#!/bin/bash\niptables-restore < #{node['diptables']['rules_path']}\n"
            action :create
        end
    else
        Chef::Log.warn("Don't know how to set up automatic iptables on your distribution, sorry. Please submit a bug ticket at https://github.com/wk8/cookbook-iptables/issues")
    end
end
