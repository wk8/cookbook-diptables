# This recipe is meant to test that the provider_mixin lib
# will log an explicit error message if creating a new
# diptables_* resource after having already applied rules
# in the current run

diptables_tcp_udp_rule 'ssh' do
  dport 22
end

diptables_apply 'apply'

diptables_tcp_udp_rule 'http' do
  dport 80
end
