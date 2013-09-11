action :add do
    Chef::Log.debug("Setting policy for #{new_resource.table} : #{new_resource.chain} to #{new_resource.policy}")
    node.ensure_iptables_will_run_after cookbook_name
    node.iptables_config.add_policy new_resource
    new_resource.updated_by_last_action true
end
