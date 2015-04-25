class Chef::Resource::DiptablesTcpUdpRule < Chef::Resource::DiptablesRule
  self.resource_name = :diptables_tcp_udp_rule

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

  def validate_diptables_params
    if source_query && source
      error_msg = "You can't use both the 'source' and 'source_query' attributes with the DiptablesTcpUdpRule resource"
      raise DiptablesCookbook::Exception::InvalidResourceAttrs.new(error_msg)
    end

    super
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
    if source
      source_array = if source.kind_of? String
        [source]
      else
        source
      end
      result = source_array.map{ |s| "#{raw_rule} -s #{s}" }
    else
      if source_query
        raw_rule += " -s %<#{SOURCE_PLACEHOLDER}>s"
      end
      result = [raw_rule]
    end
    Chef::Log.debug("Rule built for #{self} : #{result}")
    result
  end
end


class Chef::Provider::DiptablesTcpUdpRule < Chef::Provider::DiptablesRule
end
