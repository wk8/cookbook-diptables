# This recipe is mostly a hack to make the dev VM more delightful:
# it drops a profile file to have ChefDK's bin dir in the path
# TODO: should IMHO be part of the chef-dk cookbook, should send a
# PR their way

file '/etc/profile.d/chef_dk_profile.sh' do
  content "#!/bin/bash\nexport PATH=\"/opt/chefdk/embedded/bin:$PATH\"\n"
end
