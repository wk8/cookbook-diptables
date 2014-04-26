class Chef::Node
    def iptables_config
        @iptables_config = IPTablesConfig.new if @iptables_config.nil?
        @iptables_config
    end

    # we need the diptables::default recipe to be run after all the diptables LWRPs have been defined
    # otherwise the rules added after won't be enforced
    # so this a flag to ensure that
    # see also the chef_handler_diptables.rb and diptables_handler_definer.rb files
    def diptables_has_run new_state = nil
        node.run_state[:diptables_has_run] = new_state unless new_state.nil?
        node.run_state[:diptables_has_run]
    end

    def diptables_handler_defined new_state = nil
        node.run_state[:diptables_handler_defined] = new_state unless new_state.nil?
        node.run_state[:diptables_handler_defined]
    end
end
