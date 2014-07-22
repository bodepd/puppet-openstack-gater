
$jenkins_username = 'jenkins_user'
$jenkins_password = 'jenkins_password'

$jenkins_server = 'http://11.2.3.11:8080'

if $::role == 'jenkinsserver' {

  include puppet_openstack_tester::zuul

  include puppet_openstack_tester::puppet_jobs

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
    gerrit_user          => hiera('gerrit_user', 'puppet-openstack-ci-user'),
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

} elsif $::role == 'jenkinsclient' {
  # install a jenkins slave configured to launch jobs using heat
  package { 'git':
    ensure => installed,
  }
  class { 'jenkins::slave':
    masterurl => hiera('jenkins_server', $jenkins_server),
  }
  include openstack_extras::repo
  include heat::client
  class { 'openstack_tester::heat_creds':
    username              => hiera('openstack_user_name', 'bodepd'),
    password              => hiera('openstack_user_password'),
    local_user            => 'jenkins-slave',
    tenant_id             => hiera('openstack_tenant_id', '914259'),
    heat_endpoint         => hiera('openstack_heat_endpoint', 'ord.orchestration.api.rackspacecloud.com'),
    keystone_endpoint     => hiera('openstack_keystone_endpoint', 'identity.api.rackspacecloud.com'),
    openstack_private_key => hiera('openstack_private_key')
  }
} else {
  fail("Undefined role: ${::role}")
}
