Vagrant.configure(2) do |config|
  if Vagrant.has_plugin?('vagrant-gatling-rsync')
    config.gatling.rsync_on_startup = false
  end
end
