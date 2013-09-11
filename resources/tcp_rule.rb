actions :add
default_action :add

attribute :table, :kind_of => String, :default => 'filter'
attribute :chain, :kind_of => String, :default => 'INPUT'
attribute :interface, :kind_of => [String, FalseClass], :default => false
attribute :source, :kind_of => [String, Array, FalseClass], :default => false
attribute :port, :kind_of => [Fixnum, String, FalseClass], :default => false
attribute :jump, :kind_of => [String, FalseClass], :default => 'ACCEPT'
attribute :source_query, :kind_of => [String, FalseClass], :default => false
attribute :source_method, :kind_of => String, :default => 'ipaddress' 
attribute :same_environment, :kind_of => [TrueClass, FalseClass], :default => false

SOURCE_PLACEHOLDER = 'source'

# returns the rule attribute to pass to the vanilla diptables_rule resource
def build_rule
    Chef::Application.fatal!("You can't use both the 'source' and 'source_query' attributes with the DiptablesTcpRule resource!") if source_query && source
    rule = ""
    rule += "-i #{interface} " if interface
    rule += "--proto tcp "
    rule += "--dport #{port} " if port
    if source
        @source = [source] if source.kind_of? String
        result = source.map{ |s| "#{rule}-s #{s}" }
    elsif source_query
        rule += "-s %<#{SOURCE_PLACEHOLDER}>s"
        result = [rule]
    end
    Chef::Log.debug("Rule built for #{name} : #{result}")
    result
end
