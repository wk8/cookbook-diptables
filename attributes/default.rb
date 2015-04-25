case node['platform_family']
when 'debian'
  default['diptables']['rules_path'] = '/etc/iptables-rules'
when 'rhel'
  default['diptables']['rules_path'] = '/etc/sysconfig/iptables'
else
  default['diptables']['rules_path'] = '/etc/iptables-rules'
  Chef::Log.warn("Not sure where to put the rules on your distribution. Please submit a bug ticket at https://github.com/wk8/cookbook-iptables/issues")
end

default['diptables']['dry_run'] = false

# Can be used to have the diptables::default recipe create
# rules and policies from node attributes
# The preferred method should be to define resources in your own
# recipes, though.
# If you insist on using this, each added resource should be mapping
# the resource's name to its type and attributes, for example
#   node['diptables']['resources'] = {
#     'diptables_tcp_udp_rule[allow SSH]' => {
#       'dport' => 22
#     },
#     'diptables_rule[reject the rest]' => {
#       'jump' => 'REJECT'
#     }
#   }
# It should be noted this is safe to do only because Ruby hash
# do preserve insertion order since Ruby 1.9
default['diptables']['resources'] = Mash.new
