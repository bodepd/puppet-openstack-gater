Vagrant.configure("2") do |config|

#  ENV['http_proxy'] = 'http://10.22.3.1:3128'
#  ENV['https_proxy'] = 'http://10.22.3.1:3128'

  config.vm.box      = 'hashicorp/precise64'

  {
    :puppetmaster  => '10',
    :jenkinsserver => '11',
    :jenkinsclient => '12',
    :reposerver    => '13',
    :etcd          => '14',
  }.each do |node_name, number|

    config.vm.define(node_name) do |config|

      config.vm.synced_folder("hiera/", '/etc/puppet/hiera/')
      config.vm.synced_folder("modules/", '/etc/puppet/modules/')

      if node_name == :etcd
        config.vm.provision :shell, :inline => "echo 'deb file:/vagrant/packages ./'  > /etc/apt/sources.list.d/etcd.list;echo 'APT::Get::AllowUnauthenticated \"true\";' > /etc/apt/apt.conf.d/99unauth "
      end

      if ENV['http_proxy']
        config.vm.provision :shell, :inline => "echo 'export http_proxy=#{ENV['http_proxy']}'  > /etc/profile.d/proxy.sh"
        if ENV['https_proxy']
        config.vm.provision :shell, :inline => "echo 'export https_proxy=#{ENV['https_proxy']}' >> /etc/profile.d/proxy.sh"
        end
        config.vm.provision 'shell', :inline =>
        "echo \"Acquire::http { Proxy \\\"#{ENV['http_proxy']}\\\" }\" > /etc/apt/apt.conf.d/03proxy"
      end

      # run apt-get update and install pip
      unless ENV['NO_APT_GET_UPDATE'] == 'true'
        config.vm.provision 'shell', :inline =>
        'apt-get update; apt-get install -y git curl;PIP_GET_PIP_URL=https://bootstrap.pypa.io/get-pip.py;curl -O $PIP_GET_PIP_URL || wget $PIP_GET_PIP_URL;python get-pip.py'
      end

      config.vm.network "private_network", :ip => "10.22.3.#{number}"
      config.vm.network "private_network", :ip => "10.22.4.#{number}"
      config.vm.provision(:puppet) do |puppet|
         puppet.manifests_path    = 'manifests'
        puppet.manifest_file     = 'setup.pp'
        puppet.module_path       = 'modules'
      end
      config.vm.provision(:puppet) do |puppet|
        puppet.manifests_path    = 'manifests'
        puppet.manifest_file     = 'site.pp'
        puppet.module_path       = 'modules'
        puppet.options           = ['--hiera_config=/etc/puppet/hiera/hiera.yaml']
        puppet.facter            = { 'role' => node_name }
      end
    end
  end
end
