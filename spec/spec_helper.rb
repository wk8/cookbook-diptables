require 'chefspec'
require 'chefspec/berkshelf'

TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$: << File.expand_path(File.dirname(__FILE__))

OHAI_SYSTEM = Ohai::System.new
OHAI_SYSTEM.all_plugins('platform')
TEST_PLATFORM = OHAI_SYSTEM['platform'].dup.freeze
TEST_PLATFORM_VERSION = OHAI_SYSTEM['platform_version'].dup.freeze

module DiptablesRspecHelpers
  def chef_run
    return @chef_run unless @chef_run.nil?
    @chef_run = fetch_runner_class.new(log_level: :info,
                                       platform: TEST_PLATFORM,
                                       version: TEST_PLATFORM_VERSION,
                                       step_into: fetch_step_into)
    Chef::Config.force_logger true
    @chef_run
  end

  def converge_with_resources resources_hash
    resources_hash.each do |resource_name, resource_data|
      name = resource_type ? "diptables_#{resource_type}[#{resource_name}]" : resource_name
      chef_run.node.set['diptables']['resources'][name] = resource_data
    end
    chef_run.converge('recipe[diptables::default]')
  end

  def converge_with_invalid_resource resource_data
    converge_with_resources({'invalid' => resource_data})
  end

  def assert_converge_renders resources_hash, expected_content
    converge_with_resources resources_hash
    expect(chef_run).to render_file(rules_path).with_content(expected_content)
  end

  # creates the data needed for testing search capabilities
  def create_search_data
    # create a backend role
    chef_run.create_role('backend')

    # create some other nodes
    # two backends in the same env
    chef_run.create_node('prod-backend-01', { run_list: ['role[backend]'],
                                              automatic: {ipaddress: '1.1.1.1'},
                                              normal: {secondary: {ipaddress: '2.2.2.1'}} })
    chef_run.create_node('prod-backend-02', { run_list: ['role[backend]'],
                                              automatic: {ipaddress: '1.1.1.2'},
                                              normal: {secondary: {ipaddress: '2.2.2.2'}} })
    # one staging backend
    chef_run.create_node('staging-backend-01', { run_list: ['role[backend]'],
                                                 chef_environment: 'staging',
                                                 automatic: {ipaddress: '1.1.1.3'},
                                                 normal: {secondary: {ipaddress: '2.2.2.3'}} })
    # and finally one other _default server, without the backend role
    chef_run.create_node('prod-other-01', { automatic: {ipaddress: '1.1.1.4'} })
  end

private

  def fetch_step_into
    step_into
  rescue NameError
    ['diptables_apply', "diptables_#{resource_type}"]
  end

  def fetch_runner_class
    runner_class
  rescue NameError
    ChefSpec::SoloRunner
  end

  def rules_path
    case TEST_PLATFORM
    when 'ubuntu'
      '/etc/iptables-rules'
    when 'centos'
      '/etc/sysconfig/iptables'
    end
  end
end

RSpec.configure do |config|
  config.include DiptablesRspecHelpers

  # ubuntu 12.04 and centOS do not have the BPF module for iptables
  config.filter_run_excluding :skip_bpf => true unless TEST_PLATFORM == 'ubuntu' && TEST_PLATFORM_VERSION == '14.04'
end
