case node['platform_family']
when 'debian'
    default['diptables_rules_path'] = '/etc/iptables-rules-wk'
when 'rhel'
    default['diptables_rules_path'] = '/etc/sysconfig/iptables'
else
    default['diptables_rules_path'] = '/etc/iptables-rules'
    Chef::Log.warn("Not sure where to put the rules on your distribution. Please submit a bug ticket at https://github.com/wk8/cookbook-iptables/issues")
end
