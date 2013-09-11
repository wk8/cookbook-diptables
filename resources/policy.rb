actions :add
default_action :add

attribute :table, :kind_of => String, :default => 'filter'
attribute :chain, :kind_of => String, :default => 'INPUT'
attribute :policy, :equal_to => ['ACCEPT', 'DROP'], :required => true
