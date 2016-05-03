# Quick word on why we're not using a plain LWRP here: we want the other
# rules to inherit from this class. And libs are loaded before LWRPs, so
# we'd have to create an empty Chef::Resource::DiptablesRule class to be
# able to inherit from it elsewhere. But the class exising or not is how
# Chef-client detects if it needs to load a LWRP from file in the 1st
# place...

require 'chef/mixin/shell_out'
# old versions of Chef don't support require_relative...
require ::File.join(::File.dirname(__FILE__), 'provider_mixin')


class Chef::Resource::DiptablesRule < Chef::Resource::LWRPBase
  resource_name :diptables_rule

  actions :prepend, :append, :insert, :add
  default_action :append

  attribute :table, kind_of: String, default: 'filter'
  attribute :chain, kind_of: String, default: 'INPUT'
  attribute :rule, kind_of: [String, Array], default: ''
  attribute :jump, kind_of: [String, FalseClass], default: 'ACCEPT'
  attribute :comment, kind_of: [TrueClass, FalseClass, String], default: lazy { |r| r.name }
  # the query to be run to get the nodes towards which this rule will apply
  attribute :query, kind_of: [String, FalseClass], default: false
  # the placeholders inside the rule string (must be named placeholders, see http://www.ruby-doc.org/core-2.0.0/Kernel.html#method-i-format)
  # mapping the placeholders name to the method's name to be run on the resulting
  # node objects to retrieve the value to place there
  # Note that these can also be attribute paths, entered as arrays
  attribute :placeholders, kind_of: Hash, default: {}
  # if true, then will force the same Chef environment in the query
  attribute :same_environment, kind_of: [TrueClass, FalseClass], default: false
  attribute :index, kind_of: Fixnum, default: -1

  attr_accessor :computed_rules

  def validate_diptables_params
    if query
      if Chef::Config[:solo] && !chef_solo_search_installed?
        raise DiptablesCookbook::Exception::SearchNotSupported.new
      end
      if placeholders.empty?
        error_msg = 'query only makes sense when used together with the placeholders attribute'
        raise DiptablesCookbook::Exception::InvalidResourceAttrs.new(error_msg)
      end
    elsif !placeholders.empty? || same_environment
      error_msg = 'placeholders or same_environment only make sense when used together with the query attribute'
      raise DiptablesCookbook::Exception::InvalidResourceAttrs.new(error_msg)
    end
  end

private

  # shamelessly copied from
  # https://github.com/opscode-cookbooks/users/blob/v1.7.0/providers/manage.rb#L32
  def chef_solo_search_installed?
    ::Search::const_get('Helper').is_a?(Class)
  rescue NameError
    false
  end
end


class Chef::Provider::DiptablesRule < Chef::Provider::LWRPBase
  include Chef::Mixin::ShellOut
  include DiptablesCookbook::ProviderMixin

  provides :diptables_rule

  use_inline_resources

  action :append do
    insert_rule -1
  end
  action :add do
    insert_rule -1
  end
  action :prepend do
    insert_rule 0
  end
  action :insert do
    insert_rule new_resource.index
  end

private

  def insert_rule index
    Chef::Log.debug("Inserting rule #{new_resource} in position #{index} to #{new_resource.table}:#{new_resource.chain} (#{new_resource.rule})")

    # bring the handler in
    define_diptables_handler

    # some validation
    new_resource.validate_diptables_params

    # compute the actual iptables rules
    chainless_string_rules = build_chainless_string_rules

    # test the new rules make sense
    test_rules(chainless_string_rules)

    # then cache them to be applied later on
    string_rules = chainless_string_rules.map { |r| add_chain_to_rule r }
    new_resource.computed_rules = string_rules
    updating_diptables_config.insert_rule index, new_resource

    # always mark as updated
    new_resource.updated_by_last_action true
  end

  # the name of the test chain on which we try out the rules
  TEST_CHAIN_NAME = '_CHEF_DIPTABLES_TEST_CHAIN'

  def build_chainless_string_rules
    raw_rules = if new_resource.rule.kind_of?(String)
      [new_resource.rule]
    else
      new_resource.rule
    end

    if new_resource.query
      raw_rules = replace_placeholders(raw_rules)
    end

    raw_rules.map do |raw_rule|
      "#{raw_rule.empty? ? '' : " #{raw_rule}"}#{new_resource.jump ? " --jump #{new_resource.jump}" : ''}"
    end
  end

  def replace_placeholders raw_rules
    query = new_resource.query
    if new_resource.same_environment
      query = "(#{query}) AND chef_environment:#{node.chef_environment}"
    end

    # perform the search
    Chef::Log.debug("Running query: #{query}, will be applied to rules #{raw_rules} and with placeholders #{new_resource.placeholders}")
    # sort by name to avoid reloading iptables when the search doesn't return
    # nodes in the same order
    nodes = search(:node, query).sort {|a, b| a.name <=> b.name}
    if nodes.empty?
      Chef::Log.warn("No result for the query #{query}")
    end
    Chef::Log.debug("Query results: #{nodes.inspect}")

    # add one rule per node, per rule template
    nodes.inject([]) do |acc, n|
      raw_rules.inject(acc) do |acc2, raw_rule|
        acc2 << sprintf(raw_rule, node_placeholders(n))
      end
    end
  end

  # Compute the placeholders' hash for a given node object
  def node_placeholders n
    Hash[new_resource.placeholders.map do |placeholder, method_or_attr_path|
      [placeholder.to_sym, node_placeholder(n, method_or_attr_path)]
    end ]
  end

  # Computes the value for a single placeholder for a given node nobject
  def node_placeholder n, method_or_attr_path
    if method_or_attr_path.kind_of? Array
      # means it's a node attribute path
      method_or_attr_path.inject(n) { |acc, attr_name| acc[attr_name] }
    else
      # means it's a method
      n.send(method_or_attr_path)
    end
  end

  # Tests the rules by briefly applying them to a dummy chain on the same table
  # (then removing them)
  def test_rules chainless_string_rules
    flush_test_chain
    begin
      shell_out! "iptables --table #{new_resource.table} --new-chain #{TEST_CHAIN_NAME}"
    rescue Mixlib::ShellOut::ShellCommandFailed => e
      raise DiptablesCookbook::Exception::InexistingTable.new("Table: #{new_resource.table} does not exist, have you created it first?\n#{e}")
    end
    chainless_string_rules.each do |chainless_string_rule|
      begin
        test_rule = add_chain_to_rule(chainless_string_rule, TEST_CHAIN_NAME)
        shell_out! "iptables --table #{new_resource.table} #{test_rule}"
      rescue Errno::ENOENT
        raise DiptablesCookbook::Exception::IptablesNotFound.new
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        raise DiptablesCookbook::Exception::InvalidRule.new("Invalid rule:\n#{chainless_string_rule}\n#{e}")
      end
    end
  ensure
    flush_test_chain
  end

  def flush_test_chain
    # best effort, we don't check the exit status here
    shell_out "iptables --table #{new_resource.table} --flush #{TEST_CHAIN_NAME}"
    shell_out "iptables --table #{new_resource.table} --delete-chain #{TEST_CHAIN_NAME}"
  end

  def add_chain_to_rule chainless_string_rule, chain = nil
    unless chain
      chain = new_resource.chain
    end
    value = chainless_string_rule.strip
    "-A #{chain}#{value.empty? ? '' : " #{value}"}"
  end
end
