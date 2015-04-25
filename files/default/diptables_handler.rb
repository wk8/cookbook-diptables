require 'chef/log'

class DiptablesCookbook
  class DiptablesHandler < Chef::Handler
    def report
      unless node.run_state[:diptables_config_applied]
        Chef::Log.info("Applying diptables rules and policies...")
        apply_resource = node.run_state[:diptables_handler_apply_resource]
        apply_resource.run_action :apply
      end
    end
  end
end
