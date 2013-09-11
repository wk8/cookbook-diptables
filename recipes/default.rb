# Cookbook Name:: diptables
# Recipe:: default

execute 'reload-iptables' do
    command "iptables-restore < #{node['diptables_rules_path']}"
    user 'root'
    action :nothing
end

template node['diptables_rules_path'] do
    source 'iptables_rules.erb'
    notifies :run, 'execute[reload-iptables]'
    action :create
end

# set iptables to autolad
case node['platform_family']
when 'debian'
  # TODO: Generalize this for other platforms somehow
    file '/etc/network/if-up.d/iptables-rules' do
        owner 'root'
        group 'root'
        mode '0755'
        content "#!/bin/bash\niptables-restore < #{node['diptables_rules_path']}\n"
        action :create
    end
else
    Chef::Log.warn("Don't know how to set up automatic iptables on your distribution, sorry. Please submit a bug ticket at https://github.com/wk8/cookbook-iptables/issues")
end
