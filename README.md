# Intro

This project is intended to hold the code that will bootstrap
a CI environment from scratch that is capable of gating
the puppet-openstack modules.

In general, this project tried to re-use as many components
as possible from openstack-infra's modules.

# Building Out base environment

This project supports two methods of building out the environment.

1. Vagrant - this is intended to be used for testing and development
of this project as it supports a much faster way to iterate on
and verify local code changes.

2. Heat - This project also ships with heat templates that are intended
to allow a user to build out and manage a CI environment in production.
Using heat assumes that your changes have already been pushed to the
relevant code repositories.

## Initialization

Data needs to be populated to the local file

````
hiera/data/user.yaml
````

The following data needs to be applied there:

### data to connect to gerrit

* gerrit\_user:

The user to connect to gerrit as:

* zuul\_ssh\_private\_key:

Private key that zuul will use to authenticate to gerrit

### Data required to connect to openstack

* openstack\_private\_key:

Private key that is used to authenticate with openstack for
usage of heat on the jenkins slaves

* openstack\_user\_password:

Password required by your use to authenticate with openstack

* openstack\_user\_name:

Name of user to authenticate with openstack

* openstack\_tenant\_id:

Id of tenant to use for authentication

* openstack\_heat\_endpoint:

URL to use to contact heat.

* openstack\_keystone\_endpoint:

URL to use to contact keystone.

## Vagrant instructions

* install ruby and rubygems
* install vagrant and virtualbox
* install librarian-puppet-simple

````
gem install librarian-puppet-simple
````

* download modules

````
gem install librarian-puppet-simple
````

## Heat instructions

* install machine as local heat client

In order to install heat, you need to set up a heat client

* issue heat stack-build command

### Post installation

The following steps are required regardless of how your installation was performed:

* enable gearman plugin for jenkins

You have to click for this (lame!!!)
go into the jenkins config section, find the gearman section, and click on enable.

* set up user auth manually

TBH, I'm not even mucking with auth atm. Jenkins is so lame ;(


## Installing etcd

In order to build out etd, you need to build the package yourself:

### creating the package

On an Ubuntu system, do the following:

````
apt-get install ruby-dev gcc make
gem install fpm
git clone https://github.com/solarkennedy/etcd-packages
cd etcd-packages
make deb
````

Copy the resulting deb into the local packages directory for vagrant testing (or move it to
some available local directory)

### setting up the local repo

For my simple vagrant tests, I will just setup a local package repo
in ./packages

````
mkdir packages
cp etcd-packages/etcd_0.4.3_amd64.deb packages
cd packages
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
````

### setting up local repo access

Now, on machines that want to use this package, add the following to: /etc/apt/sources.list.d/etcd.list

````
deb file:/vagrant/packages ./
````
