class Chef::Resource::DiptablesTcpUdpRule < Chef::Resource::DiptablesRule
  resource_name :diptables_tcp_udp_rule

  attribute :proto, :equal_to => ['tcp', 'udp'], :default => 'tcp'
  attribute :interface, :kind_of => [String, FalseClass], :default => false
  attribute :source, :kind_of => [String, Array, FalseClass], :default => false
  attribute :dport, :kind_of => [Fixnum, String, Array, FalseClass], :default => false
  attribute :source_query, :kind_of => [String, FalseClass], :default => false
  attribute :source_method, :kind_of => [String, Array], :default => 'ipaddress' 

  def rule
    @rule ||= build_rule
  end

  def query
    source_query
  end

  def placeholders
    source_query ? {SOURCE_PLACEHOLDER => source_method} : {}
  end

private

  SOURCE_PLACEHOLDER = :_diptables_tcp_udp_source_placeholder_

  def build_rule
    raw_rule = ""
    raw_rule += "-i #{interface}" if interface
    raw_rule += " --proto #{proto}"

    if dport
      if dport.kind_of? Array
        # multiport rule
        raw_rule += " -m multiport --dports #{dport.join(',')}"
      else
        # either a Fixnum or a String; either way, single port or range of ports
        raw_rule += " --dport #{dport}"
      end
    end

    rules = []

    if source
      sources = if source.kind_of? String
          [source]
        else
          source
        end

      rules += sources.map{ |s| "#{raw_rule} -s #{s}" }
    end

    if source_query
      rules << "#{raw_rule} -s %<#{SOURCE_PLACEHOLDER}>s"
    end

    if rules.empty?
      rules << raw_rule
    end

    Chef::Log.debug("Rule built for #{self} : #{rules}")
    rules
  end
end


class Chef::Provider::DiptablesTcpUdpRule < Chef::Provider::DiptablesRule
  provides :diptables_tcp_udp_rule
end
