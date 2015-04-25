include DiptablesCookbook::ProviderMixin

use_inline_resources

action :add do
  Chef::Log.debug("Setting policy for #{new_resource.table} : #{new_resource.chain} to #{new_resource.policy}")
  define_diptables_handler
  updating_diptables_config.set_policy new_resource
  new_resource.updated_by_last_action true
end
