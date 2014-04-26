# This module is meant to be included in all of this cookbook's LWRPs to define
# our custom Chef handler to make sure the default recipe is indeed run after
# some rules have been defined

module DiptablesHandlerDefiner

    def define_diptables_handler
        # there's no sense in defining that now if the diptables::default recipe has already run!
        if node.diptables_has_run
            Chef::Application.fatal! 'You cannot define any more diptables LWRPs now that the diptables::default recipe has run!'
        end

        # no need to do anything if we've already done that
        return if node.diptables_handler_defined

        # first copy the handler file to the node
        remote_directory node['chef_handler']['handler_path'] do
            cookbook 'diptables'
            source 'handlers'
            recursive true
            action :create
        end

        # then register the handler
        chef_handler 'DiptablesHandler' do
            source ::File.join(node['chef_handler']['handler_path'], 'diptables_handler.rb')
            supports :report => true, :exception => false
            action :enable
        end

        # flag this as done
        node.diptables_handler_defined true
    end

end
