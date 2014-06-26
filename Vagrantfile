Vagrant.configure("2") do |config|

  config.vm.box     = 'ubuntu1204_puppet3_2_1'
  # TODO I still need to build out a box with the correct versions
  #config.vm.box_url = 'http://files.vagrantup.com/precise64.box'

  {
    :puppetmaster  => '10',
    :jenkinsserver => '11',
    :jenkinsclient => '12'
  }.each do |node_name, number|

    config.vm.synced_folder("hiera/", '/etc/hiera/')

    # run apt-get update and install pip
    config.vm.provision 'shell', inline:
      'apt-get update; PIP_GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py;curl -O $PIP_GET_PIP_URL || wget $PIP_GET_PIP_URL;python get-pip.py'

    config.vm.define(node_name) do |config|
      config.vm.network "private_network", :ip => "11.2.3.#{number}"
      config.vm.network "private_network", :ip => "11.2.4.#{number}"
      config.vm.provision(:puppet) do |puppet|
        puppet.manifests_path    = 'manifests'
        puppet.manifest_file     = 'site.pp'
        puppet.module_path       = 'modules'
        puppet.options           = ['--hiera_config=/etc/hiera/hiera.yaml', '--debug']
        puppet.facter            = { 'role' => node_name }
      end
    end
  end
end
