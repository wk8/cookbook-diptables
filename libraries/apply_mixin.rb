module DiptablesDelayedApply
  def diptables_delayed_apply()
    if !node.run_state[:diptables_apply_defined] 
      apply_rsrc = diptables_apply 'apply' do
        action :nothing
      end
      node.run_state[:diptables_apply_defined] = true      
      new_resource.notifies :apply, apply_rsrc, :delayed
    end
  end
end