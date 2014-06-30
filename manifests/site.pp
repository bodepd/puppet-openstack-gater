
$jenkins_username = 'jenkins_user'
$jenkins_password = 'jenkins_password'

if $::role == 'jenkinsserver' {

  include puppet_openstack_tester::puppet_jobs

  Jenkins::Plugin {
    notify => Service['jenkins'],
  }

  Service <| title == 'zuul' |> {
    ensure  => running,
    require +> Class['zuul'],
  }

  Service <| title == 'zuul-merger' |> {
    ensure  => running,
    require => Service['zuul'],
  }

  file { '/etc/jenkins_jobs/config':
    ensure => directory,
    before => Exec['jenkins_jobs_update'],
  }

  service { 'jenkins':
    ensure  => running,
    enable  => true,
    start   => '/usr/sbin/service jenkins start;/bin/sleep 120',
    before  => Class['puppet_openstack_tester::puppet_jobs'],
  }

  file { '/home/zuul/.ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
  }

  # why do I have to add this and they don't perhaps b/c something was wrong with
  # the ssh agent on the image that I created?
  file { '/home/zuul/.ssh/config':
    owner   => 'zuul',
    group   => 'zuul',
    content => "Host review.openstack.org\n  IdentityFile /var/lib/zuul/ssh/id_rsa\n  StrictHostKeyChecking no"
  }

  jenkins::plugin { 'ansicolor':
    version => '0.3.1',
  }

   class { '::jenkins::master':
    # this is very specific to the vagrant environment
    vhost_name              => $::ipaddress_eth1,
    serveradmin             => 'root@localhost',
    logo                    => 'openstack.png',
    #ssl_cert_file           => $prv_ssl_cert_file,
    #ssl_key_file            => $prv_ssl_key_file,
    #ssl_chain_file          => $ssl_chain_file,
    #ssl_cert_file_contents  => $ssl_cert_file_contents,
    #ssl_key_file_contents   => $ssl_key_file_contents,
    #ssl_chain_file_contents => $ssl_chain_file_contents,
    jenkins_ssh_private_key => hiera('jenkins_private_key'),
    jenkins_ssh_public_key  => hiera('jenkins_public_key'),
  }

  #jenkins::plugin { 'build-timeout':
  #  version => '1.13',
  #}
  #jenkins::plugin { 'copyartifact':
  #  version => '1.22',
  #}
  #jenkins::plugin { 'dashboard-view':
  #  version => '2.3',
  #}
  #jenkins::plugin { 'envinject':
  #  version => '1.70',
  #}
  jenkins::plugin { 'gearman-plugin':
    version => '0.0.3',
  }
  jenkins::plugin { 'git':
    version => '1.1.23',
  }
  #jenkins::plugin { 'greenballs':
  #  version => '1.12',
  #}
  jenkins::plugin { 'htmlpublisher':
    version => '1.0',
  }
  #jenkins::plugin { 'extended-read-permission':
  #  version => '1.0',
  #}
  #jenkins::plugin { 'postbuild-task':
  #  version => '1.8',
  #}
  #jenkins::plugin { 'zmq-event-publisher':
  #  version => '0.0.3',
  #}
#  TODO(jeblair): release
#  jenkins::plugin { 'scp':
#    version => '1.9',
#  }
  #jenkins::plugin { 'violations':
  #  version => '0.7.11',
  #}
  jenkins::plugin { 'jobConfigHistory':
    version => '1.13',
  }
  #jenkins::plugin { 'monitoring':
  #  version => '1.40.0',
  #}
  #jenkins::plugin { 'nodelabelparameter':
  #  version => '1.2.1',
  #}
  jenkins::plugin { 'notification':
    version => '1.4',
  }
  jenkins::plugin { 'openid':
    version => '1.5',
  }
  #jenkins::plugin { 'parameterized-trigger':
  #  version => '2.15',
  #}
  jenkins::plugin { 'publish-over-ftp':
    version => '1.7',
  }
  jenkins::plugin { 'rebuild':
    version => '1.14',
  }
  jenkins::plugin { 'simple-theme-plugin':
    version => '0.2',
  }
  jenkins::plugin { 'timestamper':
    version => '1.3.1',
  }
  jenkins::plugin { 'token-macro':
    version => '1.5.1',
  }
  #jenkins::plugin { 'url-change-trigger':
  #  version => '1.2',
  #}
  jenkins::plugin { 'urltrigger':
    version => '0.24',
  }

  package { 'git':
    ensure => installed,
  }

  class { 'jenkins::job_builder':
    url      => 'http://127.0.0.1:8080',
    username => $jenkins_user,
    password => $jenkins_password,
    require  => Package['git']
  }

  class { '::zuul':
    vhost_name           => $::ipaddress_eth2,
    gearman_server       => '127.0.0.1',
    gerrit_server        => 'review.openstack.org',
    # I need to create another user for this so that I don't have to use my own...
    gerrit_user          => 'puppet-openstack-ci-user',
    # private key for gerrit user
    zuul_ssh_private_key => hiera('zuul_ssh_private_key'),
    url_pattern          => '',
    zuul_url             => '',
    job_name_in_report   => true,
    status_url           => "http://${::ipaddress_eth2}/",
    #statsd_host          => $statsd_host,
    #git_email            => 'jenkins@openstack.org',
    #git_name             => 'OpenStack Jenkins',
  }

  class { '::zuul::server': }
  class { '::zuul::merger': }

  file { '/etc/zuul/layout.yaml':
    ensure => present,
    source => 'puppet:///modules/puppet_openstack_tester/zuul/layout.yaml',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/openstack_functions.py':
    ensure => present,
    source => 'puppet:///modules/puppet_openstack_tester/zuul/openstack_functions.py',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/logging.conf':
    ensure => present,
    source => 'puppet:///modules/puppet_openstack_tester/zuul/logging.conf',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/gearman-logging.conf':
    ensure => present,
    source => 'puppet:///modules/puppet_openstack_tester/zuul/gearman-logging.conf',
    notify => Exec['zuul-reload'],
  }

  file { '/etc/zuul/merger-logging.conf':
    ensure => present,
    source => 'puppet:///modules/puppet_openstack_tester/zuul/merger-logging.conf',
  }
  #class { 'jenkins::slave':
  #  ssh_key => hiera('jenkins_public_key'),
  #}

} elsif $::role == 'jenkinsclient' {
  class { 'jenkins::slave':
    ssh_key => hiera('jenkins_public_key'),
  }
  jenkins_agent { $::fqdn:
    server    => hiera('jenkins_server', 'localhost'),
    username  => $jenkins_username,
    password  => $jenkins_password,
    executors => $::processorcount,
    ssh_user  => 'jenkins',
    ssh_key   => '/var/lib/jenkins/.ssh/id_rsa',
  }
} else {
  fail("Undefined role: ${::role}")
}
