

$jenkins_server = 'http://11.2.3.11:8080'

if $::role == 'jenkinsserver' {

  include ci_profiles::jenkins

  include ci_profiles::zuul

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
