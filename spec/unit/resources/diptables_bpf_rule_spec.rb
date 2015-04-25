require 'spec_helper'

describe 'diptables_bpf_rule resource', :skip_bpf => true do
  let(:resource_type) { 'bpf_rule' }

  it 'works on the canonical example' do
    resource_data = {interface: 'eth0',
                     tcpdump_rule: 'ip and ip[12:4] & 0xFFFF0000 = ip[16:4] & 0xFFFF0000',
                     additional_rule: '--proto tcp'}
    expected_content = "\n# Accept traffic from the same /16 network\n-A INPUT --proto tcp -m bpf --bytecode \"12,40 0 0 12,21 0 9 2048,32 0 0 26,84 0 0 4294901760,2 0 0 2,32 0 0 30,84 0 0 4294901760,7 0 0 5,96 0 0 2,29 0 1 0,6 0 0 65535,6 0 0 0,\" --jump ACCEPT\n\n"
    assert_converge_renders({'Accept traffic from the same /16 network' => resource_data}, expected_content)
  end
end

