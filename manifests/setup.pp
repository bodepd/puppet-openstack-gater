Apt::Source<||> -> Package<||>

include puppet::repo::puppetlabs

$puppet_version = '3.5.1-1puppetlabs1'

package { 'puppet-common':
  ensure => $puppet_version,
}

package { 'puppet':
  ensure => $puppet_version,
}
