class Chef::Node
    def iptables_config
        @iptables_config = IPTablesConfig.new if @iptables_config.nil?
        @iptables_config
    end

    # kills the chef run if the iptables cookbook is NOT scheduled to run AFTER the one specified
    # (in which case the new rules wouldn't be enforced!)
    def ensure_iptables_will_run_after current_cookbook
        Chef::Application.fatal!("The iptables resources declared in #{current_cookbook} can't be enforced since diptables doesn't run afterwards!") unless recipes.slice(recipes.index(current_cookbook), recipes.length).include?('diptables')
    end
end
