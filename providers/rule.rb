require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :add do
    Chef::Log.debug("Adding rule to #{new_resource.table} : #{new_resource.chain} (#{new_resource.rule})")
    node.ensure_iptables_will_run_after cookbook_name

    # test the new rules make sense
    test_rules

    # then apply them
    node.iptables_config.add_rule new_resource
    new_resource.updated_by_last_action true
end

private

# the name of the test chain on which we try out the rules
TEST_CHAIN_NAME = '_CHEF_IPTABLES_TEST'

def test_rules
    shell_out("iptables --table #{new_resource.table} --delete-chain #{TEST_CHAIN_NAME}")
    shell_out! "iptables --table #{new_resource.table} --new-chain #{TEST_CHAIN_NAME}"
    begin
        new_resource.rules.each do |rule|
            test_rule = rule.gsub("-A #{new_resource.chain}", "-A #{TEST_CHAIN_NAME}")
            shell_out!("iptables --table #{new_resource.table} #{test_rule}")
        end
    ensure
        shell_out("iptables --table #{new_resource.table} --flush #{TEST_CHAIN_NAME}")
        shell_out("iptables --table #{new_resource.table} --delete-chain #{TEST_CHAIN_NAME}")
    end
end
