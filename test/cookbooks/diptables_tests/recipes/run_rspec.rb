# Runs the rspec/chefspec suite

execute 'Run the chefspec suite for diptables' do
  cwd node['diptables_tests']['cookbook_root']
  # adding the path to chef DK executables
  environment({'PATH' => "/opt/chefdk/embedded/bin:#{ENV['PATH']}"})
  command 'rspec --format documentation --color'
end
