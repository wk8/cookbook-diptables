# See more doc at https://github.com/cloudflare/bpftools

require 'chef/mixin/shell_out'


class Chef::Resource::DiptablesBpfRule < Chef::Resource::DiptablesRule
  resource_name :diptables_bpf_rule

  attribute :tcpdump_rule, kind_of: [String, Array], default: ''
  # Only used to generate the bytecode, not in the actual rule!
  attribute :interface, kind_of: [String, FalseClass], default: false
  attribute :additional_rule, kind_of: [String, Array], default: ''

  include Chef::Mixin::ShellOut

  def rule
    @rule ||= build_rule
  end

  def build_rule
    shell_response = shell_out! "tcpdump -p#{interface ? " -i #{interface}" : ''} -ddd '#{tcpdump_rule}'"
    bpf_string = shell_response.stdout.gsub("\n", ',')
    "#{additional_rule} -m bpf --bytecode \"#{bpf_string}\""
  rescue Errno::ENOENT
    raise DiptablesCookbook::Exception::TcpdumpNotFound.new
  end
end


class Chef::Provider::DiptablesBpfRule < Chef::Provider::DiptablesRule
  provides :diptables_bpf_rule
end
