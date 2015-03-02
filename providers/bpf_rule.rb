# This LWRP is actually just a convenient alias for the rule one

action :add do
  diptables_rule new_resource.name do
    table new_resource.table
    chain new_resource.chain
    rule new_resource.build_rule
    jump new_resource.jump
    comment new_resource.comment
    query new_resource.query
    same_environment new_resource.same_environment
    placeholders new_resource.placeholders
  end
end
