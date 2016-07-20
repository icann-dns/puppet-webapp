# == Class: webapp
#
define webapp::python (
  $system_packages     = [],
  $pip_packages        = [],
  $git_source          = undef,
  $git_revision        = 'master',
  $user                = 'www-data',
  $domain_name         = undef,
  $docroot_subfolder   = '/',
  $wsgi_script_aliases = 'webapp.wsgi',
  $use_ssl             = false,
  $ssl_cert            = undef,
  $ssl_key             = undef,
  $ssl_chain           = undef,
  $options             = ['Indexes','FollowSymLinks','MultiViews'],
  $cron_jobs           = {},
) {
  validate_array($system_packages)
  validate_array($pip_packages)
  if ! $git_source {
    fail("you must specify git_source for webapp::define[${name}]")
  }
  validate_string($git_source)
  validate_string($git_revision)
  validate_string($user)
  if ! $domain_name {
    fail("you must specify domain_name for webapp::define[${name}]")
  }
  validate_string($domain_name)
  validate_absolute_path($docroot_subfolder)
  validate_string($wsgi_script_aliases)
  validate_bool($use_ssl)
  if $use_ssl {
    validate_absolute_path($ssl_cert)
    validate_absolute_path($ssl_key)
  }
  if $ssl_chain {
    validate_absolute_path($ssl_chain)
  }
  validate_array($options)
  validate_hash($cron_jobs)

  $approot = "${webapp::web_root}/${name}"

  ensure_packages(['git'])
  ensure_packages($system_packages)

  include apache::mod::wsgi

  vcsrepo { $approot:
    ensure   => latest,
    provider => git,
    user     => $user,
    revision => $git_revision,
    source   => $git_source,
    require  => Package[$system_packages],
  }
  python::virtualenv {$approot:
    ensure  => present,
    path    => ['/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    owner   => $user,
    require => Vcsrepo[$approot],
  }
  $pip_packages_resources = unique_pip_packages($pip_packages, $approot, Vcsrepo[$approot])
  create_resources(python::pip, $pip_packages_resources)

  if $use_ssl {
    apache::vhost { "${domain_name}-redirect":
      servername      => $domain_name,
      docroot         => "${approot}${docroot_subfolder}",
      port            => 80,
      redirect_status => 'permanent',
      redirect_dest   => "https://${domain_name}/",
      require         => Vcsrepo[$approot],
      manage_docroot  => false,
    }
    apache::vhost { "${domain_name}-ssl":
      servername                  => $domain_name,
      docroot                     => "${approot}${docroot_subfolder}",
      port                        => 443,
      ssl                         => true,
      ssl_cert                    => $ssl_cert,
      ssl_key                     => $ssl_key,
      ssl_chain                   => $ssl_chain,
      ssl_protocol                => 'all -SSLv2 -SSLv3',
      wsgi_daemon_process         => $name,
      wsgi_process_group          => $name,
      wsgi_script_aliases         => {
        '/'                       => "${approot}/${wsgi_script_aliases}",
      },
      wsgi_daemon_process_options =>  {
        'user' => $user,
      },
      options                     => $options,
      manage_docroot              => false,
      require                     => Vcsrepo[$approot],
    }
  } else {
    apache::vhost { $domain_name:
      servername                  => $domain_name,
      docroot                     => "${approot}${docroot_subfolder}",
      wsgi_daemon_process         => $name,
      wsgi_process_group          => $name,
      port                        => 80,
      wsgi_daemon_process_options =>  {
        'user' => $user,
      },
      wsgi_script_aliases         => {
        '/' => "${approot}/${wsgi_script_aliases}",
      },
      options                     => $options,
      manage_docroot              => false,
      require                     => Vcsrepo[$approot],
    }
  }
  create_resources(cron, $cron_jobs)
}
