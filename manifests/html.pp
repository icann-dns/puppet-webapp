# == Class: webapp
#
define webapp::html (
  $system_packages     = [],
  $puppet_source       = undef,
  $git_source          = undef,
  $git_revision        = 'master',
  $user                = 'www-data',
  $domain_name         = undef,
  $docroot_subfolder   = '/',
  $use_ssl             = false,
  $ssl_cert            = undef,
  $ssl_key             = undef,
  $ssl_chain           = undef,
  $options             = ['Indexes','FollowSymLinks','MultiViews'],
  $cron_jobs           = {},
) {
  validate_array($system_packages)
  if $git_source and $puppet_source {
    fail("you cannot specify git_source and puppet_source for webapp::define[${name}]")
  }
  if ! $git_source and ! $puppet_source {
    fail("you must specify git_source or puppet_source for webapp::define[${name}]")
  }
  if $git_source {
    validate_string($git_source)
    validate_string($git_revision)
  }
  if $puppet_source {
    validate_string($puppet_source)
  }
  validate_string($user)
  if ! $domain_name {
    fail("you must specify domain_name for webapp::html[${name}]")
  }
  validate_string($domain_name)
  validate_absolute_path($docroot_subfolder)
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
    }
  } else {
    file { $approot:
      source  => $puppet_source,
      purge   => false,
      recurse => true,
    }
  }
  if $use_ssl {
    apache::vhost { "${domain_name}-redirect":
      servername      => $domain_name,
      docroot         => "${approot}${docroot_subfolder}",
      port            => 80,
      redirect_status => 'permanent',
      redirect_dest   => "https://${domain_name}/",
    }
    apache::vhost { "${domain_name}-ssl":
      servername   => $domain_name,
      docroot      => "${approot}${docroot_subfolder}",
      port         => 443,
      ssl          => true,
      ssl_cert     => $ssl_cert,
      ssl_key      => $ssl_key,
      ssl_chain    => $ssl_chain,
      ssl_protocol => 'all -SSLv2 -SSLv3',
      options      => $options,
    }
  } else {
    apache::vhost { $domain_name:
      servername => $domain_name,
      docroot    => "${approot}${docroot_subfolder}",
      port       => 80,
      options    => $options,
    }
  }
  create_resources(cron, $cron_jobs)
}
