actions :add
default_action :add

# See more doc at https://github.com/cloudflare/bpftools

attribute :table, :kind_of => String, :default => 'filter'
attribute :chain, :kind_of => String, :default => 'INPUT'
attribute :tcpdump_rule, :kind_of => [String, Array], :default => ''
# Only used to generate the bytecode, not in the actual rule!
attribute :interface, :kind_of => [String, FalseClass], :default => false
attribute :additional_rule, :kind_of => [String, Array], :default => ''
attribute :jump, :kind_of => [String, FalseClass], :default => 'ACCEPT'
attribute :comment, :kind_of => [TrueClass, FalseClass, String], :default => true
# the query to be run to get the nodes towards which this rule will apply
attribute :query, :kind_of => [String, FalseClass], :default => false
# the placeholders inside the rule string (must be named placeholders, see http://www.ruby-doc.org/core-2.0.0/Kernel.html#method-i-format)
# mapping the placeholders name to the method's name to be run on the resulting
# node objects to retrieve the value to place there
attribute :placeholders, :kind_of => Hash, :default => {}
# if true, then will force the same Chef environment in the query
attribute :same_environment, :kind_of => [TrueClass, FalseClass], :default => false

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def build_rule
  shell_response = shell_out! "tcpdump -p#{interface ? " -i #{interface}" : ''} -ddd '#{tcpdump_rule}'"
  bpf_string = shell_response.stdout.gsub("\n", ',')
  "#{additional_rule} -m bpf --bytecode \"#{bpf_string}\""
end
