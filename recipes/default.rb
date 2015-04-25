# Create the resources from the node attrs, if any
DIPTABLES_RESOURCE_FROM_NODE_ATTR_REGEX = /^diptables_(rule|tcp_udp_rule|bpf_rule|policy)\[(.+)\]$/
node['diptables']['resources'].each do |resource_name, resource_data|
  match_data = DIPTABLES_RESOURCE_FROM_NODE_ATTR_REGEX.match(resource_name.to_s)
  if match_data
    self.send("diptables_#{match_data[1]}", match_data[2]) do
      resource_data.each do |attr_name, attr_value|
        self.send(attr_name, attr_value)
      end
    end
  else
    error_msg = "Ignoring the invalid resource '#{resource_name}' defined in node['diptables']['resources']"
    Chef::Log.error(error_msg)
    # also log to file, if any
    log error_msg do level :error end
  end
end

# and apply all the rules
diptables_apply 'diptables_default_apply_rules'
