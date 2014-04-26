require 'chef/log'

class DiptablesHandler < Chef::Handler
    def report
        unless node.diptables_has_run
            Chef::Log.error('Some diptables LWRPs have been defined, but the diptables::default' \
                'recipe has not been run afterwards, so your iptables rules have NOT been enforced!' \
                'Please add "recipe[diptables]" to your run_list.')
        end
    end
end
