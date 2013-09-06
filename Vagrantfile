Vagrant::Config.run do |config|
        config.vm.box     = "KFSDev"
        config.vm.box_url = "http://dl.dropbox.com/u/883064/F16.box"
        config.vm.provision :puppet, :module_path => "modules", :options => [ "--templatedir", "/tmp/vagrant-puppet/templates" ]
    config.vm.share_folder("templates", "/tmp/vagrant-puppet/templates", "templates")
    config.vm.share_folder("files", "/tmp/vagrant-puppet/files", "files")
end
