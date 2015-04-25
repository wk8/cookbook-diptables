require 'spec_helper'

describe 'provider_mixin library' do
  let(:runner_class) { ChefSpec::SoloRunner }
  let(:step_into) { ['diptables_apply', 'diptables_tcp_udp_rule', 'ruby_block'] }

  it 'warns vocally if creating new rules after an apply' do
    chef_run.converge('recipe[diptables_tests::provider_mixin_warning]')
    expect(chef_run).to write_log(/Diptables has already applied a partially built iptables config during this\nChef run!/).with_level(:error)
  end
end
