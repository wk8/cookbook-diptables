require 'spec_helper'

describe 'delivery::default' do
  let(:runner_class) { ChefSpec::SoloRunner }
  let(:step_into) { ['diptables_apply'] }
  let(:resource_type) { nil }

  it "refuses to include non-diptables resources from node['diptables']['resources']" do
    assert_converge_renders({'user[evil]' => {}}, '# No diptables config defined...')
    expect(chef_run).to write_log("Ignoring the invalid resource 'user[evil]' defined in node['diptables']['resources']").with_level(:error)
  end
end
