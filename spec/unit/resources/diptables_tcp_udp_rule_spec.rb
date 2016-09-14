require 'spec_helper'

describe 'diptables_tcp_udp_rule resource' do
  let(:resource_type) { 'tcp_udp_rule' }

  context 'on a solo run' do
    let(:runner_class) { ChefSpec::SoloRunner }

    it 'works on a basic example' do
      resource_data = {dport: 22, source: '1.2.3.4'}
      expected_content = "# Allow SSH from 1.2.3.4\n-A INPUT --proto tcp --dport 22 -s 1.2.3.4 --jump ACCEPT\n\n"
      assert_converge_renders({'Allow SSH from 1.2.3.4' => resource_data}, expected_content)
    end

    it 'allows to change the proto being used' do
      resource_data = {dport: 53,
                       proto: 'udp'}
      expected_content = "# Allow inbound DNS packets\n-A INPUT --proto udp --dport 53 --jump ACCEPT\n\n"
      assert_converge_renders({'Allow inbound DNS packets' => resource_data}, expected_content)
    end

    it 'allows to change the interface' do
      resource_data = {interface: 'eth1'}
      expected_content = "# Allow everything on eth1\n-A INPUT -i eth1 --proto tcp --jump ACCEPT\n\n"
      assert_converge_renders({'Allow everything on eth1' => resource_data}, expected_content)
    end

    it 'allows to use an array to specify multiple ports and port ranges' do
      resource_data = {dport: [9200, '9300:9400']}
      expected_content = "# Elasticsearch\n-A INPUT --proto tcp -m multiport --dports 9200,9300:9400 --jump ACCEPT\n\n"
      assert_converge_renders({'Elasticsearch' => resource_data}, expected_content)
    end

    it 'allows to use an array to specify multiple sources' do
      resource_data = {source: ['1.1.1.1', '2.2.2.2']}
      expected_content = "# White listed IPs\n-A INPUT --proto tcp -s 1.1.1.1 --jump ACCEPT\n-A INPUT --proto tcp -s 2.2.2.2 --jump ACCEPT\n\n"
      assert_converge_renders({'White listed IPs' => resource_data}, expected_content)
    end
  end

  context 'on a client run' do
    let(:runner_class) { ChefSpec::ServerRunner }

    let(:base_resource_data) {
      {source_query: 'role:backend',
       dport: 3306}
    }

    before(:each) { create_search_data }

    it 'can use the search' do
      expected_content = "# Backend servers to MySQL\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.1 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.2 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.3 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL' => base_resource_data}, expected_content)
    end

    it 'concatenates query and query_source if passed both' do
      with_source = base_resource_data.tap { |d| d[:source] = '99.99.99.0/24' }
      expected_content = "# Backend servers to MySQL\n-A INPUT --proto tcp --dport 3306 -s 99.99.99.0/24 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.1 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.2 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.3 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL' => with_source}, expected_content)
    end

    it 'can limit the query to nodes in the same environment' do
      with_same_env = base_resource_data.tap { |d| d[:same_environment] = true }
      expected_content = "# Backend servers to MySQL\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.1 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 1.1.1.2 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL' => with_same_env}, expected_content)
    end

    it 'can also use attribute paths to retrieve the source' do
      with_another_method = base_resource_data.tap { |d| d[:source_method] = ['secondary', 'ipaddress'] }
      expected_content = "# Backend servers to MySQL\n-A INPUT --proto tcp --dport 3306 -s 2.2.2.1 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 2.2.2.2 --jump ACCEPT\n-A INPUT --proto tcp --dport 3306 -s 2.2.2.3 --jump ACCEPT\n\n"
      assert_converge_renders({'Backend servers to MySQL' => with_another_method}, expected_content)
    end
  end
end
