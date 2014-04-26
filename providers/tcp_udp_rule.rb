# This LWRP is actually just a convenient alias for the rule one

action :add do
    diptables_rule new_resource.name do
        table new_resource.table
        chain new_resource.chain
        rule new_resource.build_rule
        jump new_resource.jump
        comment new_resource.comment
        if new_resource.source_query
            query new_resource.source_query
            same_environment new_resource.same_environment
            placeholders({new_resource.class::SOURCE_PLACEHOLDER.to_sym => new_resource.source_method})
        end
    end
end
