include DiptablesHandlerDefiner
include DiptablesDelayedApply

action :add do
    Chef::Log.debug("Setting policy for #{new_resource.table} : #{new_resource.chain} to #{new_resource.policy}")
    define_diptables_handler
    node.iptables_config.add_policy new_resource
    new_resource.updated_by_last_action true
    diptables_delayed_apply    
end
