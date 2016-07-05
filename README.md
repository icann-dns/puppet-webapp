[![Build Status](https://travis-ci.org/icann-dns/puppet-webapp.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-webapp)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/webapp.svg?maxAge=2592000)](https://forge.puppet.com/icann/webapp)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/webapp.svg?maxAge=2592000)](https://forge.puppet.com/icann/webapp)
# webapp

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with webapp](#setup)
    * [What webapp affects](#what-webapp-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with webapp](#beginning-with-webapp)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
    * [Defines](#defines)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This modules is used to deploy simple web apps

## Module Description

The modules is intended to deploy simple web applications.  Currently it only supports deploying a python web app, in this case it will create the following

## Setup

### What webapp affects

* create an apache vhost
* create python virtual environment
* clone a git repo 

### Setup Requirements 

* puppetlabs-stdlib 4.11.0
* puppetlabs-vcsrepo 1.3.2
* puppetlabs-apache 1.10.0
* stankevich-python 1.12.0

### Beginning with webapp

add the webapp class with a python app

```puppet
class {'::webapp' 
  python_apps => {
    'test' => {
      git_source  => 'git@git.example.com:root/example.git',
      domain_name => 'test.example.com',
    }
}
```

Or add the python apps to hiera
```yaml
webapp::python_apps:
  test:
    git_source: 'git@git.example.com:root/example.git'
    domain_name: 'test.example.com'
```

## Reference

### Classes

#### Public Classes

* [`webapp`](#class-webapp)

#### Private Classes

* [`webapp::params`](#class-webappparams)

#### Class: `webapp`

Main class, includes all other classes

##### Parameters (all optional)

* `web_root` (Path, Default: /srv/www): where to install the web applications
* `python_apps` (Hash, Default: {}): A hash of webapp::python objects                                        

### Defines

#### Public Defines

* [webapp::python](#define-webapppython)

#### Define: `webapp::python`

* `system_packages` (Array, Default: []): Install any stystem packages that the web app may depend on
* `pip_packages` (Array, Default: []): Install pip packages into the virtual environment for the web app
* `git_source` (String, Default: undef, Required): The source of the git repo
* `git_revision` (String, Default: 'master'): The revision/branch to clone
* `git_user` (String, Default: 'root'): The user to use when cloning the git repo
* `domain_name` (String, Default: undef, Required): The domwain name to use for the virtual host
* `docroot_subfolder` (Path, Default: /): The folder, relative to the repo where web files are
* `wsgi_script_aliases` (String, Default: 'webapp.wsgi'): file reletive to the webapp root dir to use as the wsgi script
* `conr_jobs` (Hash, Default: {}): hash of cron types to configure

## Limitations

This is where you list OS compatibility, version compatibility, etc.

## Development

This module is tested on Ubuntu 12.04, and 14.04 and FreeBSD 10 

