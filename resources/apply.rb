# A LWRP that applies the diptable rules & policies as defined so far in the
# current chef run

actions :apply
default_action :apply
attribute :name, :kind_of => String, :name_attribute => true
