# == Class: webapp
#
define webapp::python (
  String $domain_name,
  String $git_source,
  Optional[Array] $system_packages          = [],
  Optional[Array] $pip_packages             = [],
  Optional[Stdlib::Absolutepath] $ssl_cert  = undef,
  Optional[Stdlib::Absolutepath] $ssl_key   = undef,
  Optional[Stdlib::Absolutepath] $ssl_chain = undef,
  String $git_revision                      = 'master',
  String $user                              = 'www-data',
  Stdlib::Absolutepath $docroot_subfolder   = '/',
  String $wsgi_script_aliases               = 'webapp.wsgi',
  Boolean $use_ssl                          = false,
  Array[String] $options                    = ['Indexes','FollowSymLinks','MultiViews'],
  Hash $cron_jobs                           = {},
) {
  if $use_ssl {
    unless $ssl_cert and $ssl_key {
      fail('you must specify ssl_cert and ssl_key if use_ssl==true')
    }
  }
  $approot = "${webapp::web_root}/${name}"

  ensure_packages(['git'])
  ensure_packages($system_packages)

  include ::apache::mod::wsgi

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
  if $pip_packages {
    $pip_packages_resources = unique_pip_packages($pip_packages, $approot, Vcsrepo[$approot])
    create_resources(python::pip, $pip_packages_resources)
  }

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
      subscribe                   => Vcsrepo[$approot],
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
      subscribe                   => Vcsrepo[$approot],
    }
  }
  create_resources(cron, $cron_jobs)
}
