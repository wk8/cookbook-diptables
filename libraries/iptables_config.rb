class DiptablesCookbook
  class IPTablesChain
    attr_reader :name, :rules
    attr_accessor :policy

    def initialize name
      @name = name
      # the "undefined" policy for iptables
      @policy = '-'
      @rules =  []
    end

    def insert_rule index, rule
      @rules.insert(index, rule)
    end
  end

  class IPTablesTable
    attr_reader :name

    def initialize name
      @name = name
      @chains = {}
    end

    def chains
      @chains.values
    end

    def get_chain chain_name
      @chains[chain_name] ||= IPTablesChain.new(chain_name)
    end
  end

  class IPTablesConfig
    attr_accessor :applied

    def initialize
      @tables = {}
    end

    def set_policy policy
      get_table(policy.table).get_chain(policy.chain).policy = policy.policy
    end

    def insert_rule index, rule
      get_table(rule.table).get_chain(rule.chain).insert_rule(index, rule)
    end

    def tables
      @tables.values
    end

    def get_table table_name
      @tables[table_name] ||= IPTablesTable.new(table_name)
    end
  end
end
