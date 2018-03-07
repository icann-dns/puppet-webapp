# == Class: webapp
#
define webapp::html (
  String $domain_name,
  Optional[Array] $system_packages          = [],
  Optional[String] $puppet_source           = undef,
  Optional[String] $git_source              = undef,
  Optional[Stdlib::Absolutepath] $ssl_cert  = undef,
  Optional[Stdlib::Absolutepath] $ssl_key   = undef,
  Optional[Stdlib::Absolutepath] $ssl_chain = undef,
  String $git_revision                      = 'master',
  String $user                              = 'www-data',
  Stdlib::Absolutepath $docroot_subfolder   = '/',
  Boolean $use_ssl                          = false,
  Array[String] $options                    = ['Indexes','FollowSymLinks','MultiViews'],
  Hash $cron_jobs                           = {},
) {
  if $git_source and $puppet_source {
    fail("you cannot specify git_source and puppet_source for webapp::define[${name}]")
  }
  if ! $git_source and ! $puppet_source {
    fail("you must specify git_source or puppet_source for webapp::define[${name}]")
  }
  if $use_ssl {
    unless $ssl_cert and $ssl_key {
      fail('you must specify $ssl_key and $ssl_cert when $use_ssl==true')
    }
  }
  $approot = "${webapp::web_root}/${name}"
  ensure_packages($system_packages)

  if $git_source {
    ensure_packages(['git'])
    vcsrepo { $approot:
      ensure   => latest,
      provider => git,
      user     => $user,
      revision => $git_revision,
      source   => $git_source,
      require  => Package[$system_packages],
      notify   => Service['httpd'],
    }
  } else {
    file { $approot:
      source  => $puppet_source,
      owner   => $user,
      purge   => false,
      recurse => true,
      notify  => Service['httpd'],
    }
  }
  if $use_ssl {
    apache::vhost { "${domain_name}-redirect":
      servername      => $domain_name,
      docroot         => "${approot}${docroot_subfolder}",
      port            => 80,
      redirect_status => 'permanent',
      redirect_dest   => "https://${domain_name}/",
      manage_docroot  => false,
    }
    apache::vhost { "${domain_name}-ssl":
      servername     => $domain_name,
      docroot        => "${approot}${docroot_subfolder}",
      port           => 443,
      ssl            => true,
      ssl_cert       => $ssl_cert,
      ssl_key        => $ssl_key,
      ssl_chain      => $ssl_chain,
      options        => $options,
      manage_docroot => false,
    }
  } else {
    apache::vhost { $domain_name:
      servername     => $domain_name,
      docroot        => "${approot}${docroot_subfolder}",
      port           => 80,
      options        => $options,
      manage_docroot => false,
    }
  }
  create_resources(cron, $cron_jobs)
}
