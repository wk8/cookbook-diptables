require 'spec_helper'

describe 'diptables_rule resource' do
  let(:resource_type) { 'rule' }

  context 'on a solo run' do
    let(:runner_class) { ChefSpec::SoloRunner }

    it 'works on a basic example' do
      resource_data = {rule: '--proto tcp --dport 22'}
      expected_content = "# Allow SSH\n-A INPUT --proto tcp --dport 22 --jump ACCEPT\n\n"
      assert_converge_renders({'Allow SSH' => resource_data}, expected_content)
    end

    it 'accepts an array of rules' do
      resource_data = {rule: ['--proto tcp --dport 80', '--proto tcp --dport 443']}
      expected_content = "# Allow HTTP and HTTPs\n-A INPUT --proto tcp --dport 80 --jump ACCEPT\n-A INPUT --proto tcp --dport 443 --jump ACCEPT\n\n"
      assert_converge_renders({'Allow HTTP and HTTPs' => resource_data}, expected_content)
    end

    it 'raises an exception if fed an invalid rule' do
      resource_data = {rule: "I'm for sure an invalid rule!"}
      expect { converge_with_invalid_resource resource_data }.to raise_error(DiptablesCookbook::Exception::InvalidRule)
    end

    it 'raises an exception if trying to use the query feature without the chef-solo-search cookbook' do
      resource_data = {query: 'roles:backend'}
      expect { converge_with_invalid_resource resource_data }.to raise_error(DiptablesCookbook::Exception::SearchNotSupported)
    end

    it 'raises an exception if trying to use placeholders without a query' do
      resource_data = {placeholders: {:remote_ip => 'ipaddress_method'}}
      expect { converge_with_invalid_resource resource_data }.to raise_error(DiptablesCookbook::Exception::InvalidResourceAttrs)
    end

    it 'raises an exception if trying to use same_environment without a query' do
      resource_data = {same_environment: true}
      expect { converge_with_invalid_resource resource_data }.to raise_error(DiptablesCookbook::Exception::InvalidResourceAttrs)
    end

    it 'allows to change the chain being used' do
      resource_data = {rule: '--proto udp --dport 53',
                       chain: 'FORWARD'}
      expected_content = "# Forward DNS packets\n-A FORWARD --proto udp --dport 53 --jump ACCEPT\n\n"
      assert_converge_renders({'Forward DNS packets' => resource_data}, expected_content)
    end

    it 'raises an exception if using a table that does not exist' do
      resource_data = {table: 'I_DONT_EXIST'}
      expect { converge_with_invalid_resource resource_data }.to raise_error(DiptablesCookbook::Exception::InexistingTable)
    end

    it 'allows to change the jump action' do
      resource_data = {rule: '--proto tcp --dport 22',
                       jump: 'REJECT'}
      expected_content = "# Deny SSH\n-A INPUT --proto tcp --dport 22 --jump REJECT\n\n"
      assert_converge_renders({'Deny SSH' => resource_data}, expected_content)
    end

    it 'allows to not have any jump action' do
      resource_data = {jump: false,
                       rule: '-m state --state RELATED,ESTABLISHED'}
      expected_content = "# Keep established connections\n-A INPUT -m state --state RELATED,ESTABLISHED\n\n"
      assert_converge_renders({'Keep established connections' => resource_data}, expected_content)
    end

    it 'allows to customize the comment in the generated file' do
      comment = 'I love the world and accept anything!'
      resource_data = {comment: comment}
      expected_content = "# #{comment}\n-A INPUT --jump ACCEPT\n\n"
      assert_converge_renders({'dumber_than_dumb' => resource_data}, expected_content)
    end

    it 'allows to not use any comment' do
      resource_data = {comment: false}
      expected_content = "\n:INPUT - [0:0]\n-A INPUT --jump ACCEPT\n\n"
      assert_converge_renders({'dumber_than_dumb' => resource_data}, expected_content)
    end

    it 'recognizes the legacy action :add' do
      resource_data = {action: :add}
      expected_content = "\n:INPUT - [0:0]\n# Free for all!\n-A INPUT --jump ACCEPT\n\n"
      assert_converge_renders({'Free for all!' => resource_data}, expected_content)
    end

    it 'allows to prepend rules' do
      resources = {'Rule 1' => {},
                   'Rule 2' => {action: :prepend}}
      expected_content = "\n# Rule 2\n-A INPUT --jump ACCEPT\n\n# Rule 1\n-A INPUT --jump ACCEPT\n"
      assert_converge_renders(resources, expected_content)
    end

    it 'allows to insert rules at arbitrary indices' do
      resources = {'Rule 1' => {},
                   'Rule 2' => {},
                   'Rule 3' => {action: :insert,
                                index: 1}}
      expected_content = "\n# Rule 1\n-A INPUT --jump ACCEPT\n\n# Rule 3\n-A INPUT --jump ACCEPT\n\n# Rule 2\n-A INPUT --jump ACCEPT\n"
      assert_converge_renders(resources, expected_content)
    end
  end

  context 'on a client run' do
    let(:runner_class) { ChefSpec::ServerRunner }

    let(:base_resource_data) {
      {query: 'role:backend',
       placeholders: {:remote_ip => 'ipaddress_method'},
       rule: '-s %<remote_ip>s --proto tcp --dport 3306'}
    }

    before(:each) { create_search_data }

    it 'can use the search' do
      expected_content = "# Backend servers to MySQL\n-A INPUT -s 1.1.1.1 --proto tcp --dport 3306 --jump ACCEPT\n-A INPUT -s 1.1.1.2 --proto tcp --dport 3306 --jump ACCEPT\n-A INPUT -s 1.1.1.3 --proto tcp --dport 3306 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL' => base_resource_data}, expected_content)
    end

    it 'can limit the query to nodes in the same environment' do
      with_same_env = base_resource_data.tap { |d| d[:same_environment] = true }
      expected_content = "# Backend servers to MySQL (same env)\n-A INPUT -s 1.1.1.1 --proto tcp --dport 3306 --jump ACCEPT\n-A INPUT -s 1.1.1.2 --proto tcp --dport 3306 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL (same env)' => with_same_env}, expected_content)
    end

    it 'can also use attribute paths to replace the placeholders' do
      with_another_method = base_resource_data.tap { |d| d[:placeholders] = {:remote_ip => ['secondary', 'ipaddress']} }
      expected_content = "# Backend servers to MySQL (attr paths)\n-A INPUT -s 2.2.2.1 --proto tcp --dport 3306 --jump ACCEPT\n-A INPUT -s 2.2.2.2 --proto tcp --dport 3306 --jump ACCEPT\n-A INPUT -s 2.2.2.3 --proto tcp --dport 3306 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL (attr paths)' => with_another_method}, expected_content)
    end
  end
end
