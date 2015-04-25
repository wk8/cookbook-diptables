require 'spec_helper'

describe 'diptables_policy resource' do
  let(:resource_type) { 'policy' }

  it 'allows to set the policy on a chain' do
    resource_data = {policy: 'ACCEPT'}
    expected_content = "\n*filter\n:INPUT ACCEPT [0:0]\nCOMMIT\n"
    assert_converge_renders({'Allow SSH' => resource_data}, expected_content)
  end

  it 'allows to select which chain to apply said policy to' do
    resource_data = {policy: 'DROP',
                     chain: 'FORWARD'}
    expected_content = "\n*filter\n:FORWARD DROP [0:0]\nCOMMIT\n"
    assert_converge_renders({'Allow SSH' => resource_data}, expected_content)
  end
end
