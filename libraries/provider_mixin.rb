# This module is meant to be included in all of this cookbook's providers

class DiptablesCookbook
  module ProviderMixin
    # Defines and registers the handler that's responsible for applying
    # the rules at the end of a run
    def define_diptables_handler
      # do that only once
      return if node.run_state[:diptables_handler_defined]

      # first copy the handler file to the node
      directory node['chef_handler']['handler_path'] do
        recursive true
      end
      diptables_handler_path = ::File.join(node['chef_handler']['handler_path'], 'diptables_handler.rb')
      cookbook_file diptables_handler_path do
        cookbook 'diptables'
        source 'diptables_handler.rb'
      end
      # and register it
      chef_handler 'DiptablesCookbook::DiptablesHandler' do
        source diptables_handler_path
        supports :report => true, :exception => false
        action :enable
      end

      # finally, create the diptalbles_apply resource the handler
      # will converge if needed
      apply_resource = diptables_apply 'diptables_handler_apply_rules' do
        action :nothing
      end
      node.run_state[:diptables_handler_defined] = true
      node.run_state[:diptables_handler_apply_resource] = apply_resource
    end

    # Should be called by all providers when updating the config
    # Returns the current DiptablesCookbook::IPTablesConfig object
    def updating_diptables_config
      if node.run_state[:diptables_config_last_applied_by]
        # if the config has already been applied during this run, warn this is
        # not a good thing to do, since a partially built config has been
        # applied...
        apply_resource = node.run_state[:diptables_config_last_applied_by]
        error_msg = <<EOF
Diptables has already applied a partially built iptables config during this
Chef run!

It was applied by the diptables_apply resource #{apply_resource} defined at
#{apply_resource.to_text}

And you're now creating a new rule or policy with the #{new_resource} resource
defined at
#{new_resource.to_text}.

That's almost not certainly what you want: in between #{apply_resource} and
now, your node has been running with an incomplete iptables configuration!

You should consider using resource notifications to trigger the apply one, or
else as a last resort not defining any diptables_apply resource, in which case
the diptables cookbook will automatically apply the new rules at the end of
your Chef run.
EOF
        Chef::Log.error(error_msg)
        # also log to file, if any
        log error_msg do level :error end
      end
      node.run_state[:diptables_config_applied] = false
      node.run_state[:diptables_config] ||= DiptablesCookbook::IPTablesConfig.new
    end
  end
end
