
$jenkins_username = 'jenkins_user'
$jenkins_password = 'jenkins_password'

$jenkins_server = 'http://11.2.3.11:8080'

if $::role == 'jenkinsserver' {

  include puppet_openstack_tester::puppet_jobs

  #Jenkins::Plugin {
  #  notify => Service['jenkins'],
  #}

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

  #service { 'jenkins':
  #  ensure  => running,
  #  enable  => true,
  #  start   => '/usr/sbin/service jenkins start;/bin/sleep 120',
  #  before  => Class['puppet_openstack_tester::puppet_jobs'],
  #}

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

  include jenkins, jenkins::master

  Service['jenkins'] ~> Exec['sleep_two_min'] -> Exec['jenkins_jobs_update']

  exec { 'sleep_two_min':
    command     => '/bin/sleep 120',
    refreshonly => true,
  }

  class { 'jenkins_job_builder':
    url      => 'http://127.0.0.1:8080',
    username => $jenkins_user,
    password => $jenkins_password,
    require  => Package['git']
  }

   #class { '::jenkins::master':
   # # this is very specific to the vagrant environment
   # vhost_name              => $::ipaddress_eth1,
   # serveradmin             => 'root@localhost',
   # logo                    => 'openstack.png',
   # #ssl_cert_file           => $prv_ssl_cert_file,
   # #ssl_key_file            => $prv_ssl_key_file,
   # #ssl_chain_file          => $ssl_chain_file,
   # #ssl_cert_file_contents  => $ssl_cert_file_contents,
   # #ssl_key_file_contents   => $ssl_key_file_contents,
   # #ssl_chain_file_contents => $ssl_chain_file_contents,
   # jenkins_ssh_private_key => hiera('jenkins_private_key'),
   # jenkins_ssh_public_key  => hiera('jenkins_public_key'),
  #}

  jenkins::plugin { 'gearman-plugin':
    version => '0.0.3',
  }
  jenkins::plugin { 'git':
    version => '1.1.23',
  }
  jenkins::plugin { 'htmlpublisher':
    version => '1.0',
  }
  jenkins::plugin { 'jobConfigHistory':
    version => '1.13',
  }
  jenkins::plugin { 'notification':
    version => '1.4',
  }
  jenkins::plugin { 'openid':
    version => '1.5',
  }
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
  jenkins::plugin { 'urltrigger':
    version => '0.24',
  }

  package { 'git':
    ensure => installed,
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

} elsif $::role == 'jenkinsclient' {
  package { 'git':
    ensure => installed,
  }
  class { 'jenkins::slave':
    masterurl => hiera('jenkins_server', $jenkins_server),
  }
  include openstack_extras::repo
  include heat::client
  class { 'puppet_openstack_tester::heat_creds':
    filename              => '/home/jenkins-slave/heat.sh',
    username              => 'bodepd',
    password              => hiera('openstack_user_password'),
    tenant_id             => '914259',
    heat_endpoint         => 'ord.orchestration.api.rackspacecloud.com',
    keystone_endpoint     => 'identity.api.rackspacecloud.com',
    openstack_private_key => hiera('openstack_private_key')
  }
} else {
  fail("Undefined role: ${::role}")
}
