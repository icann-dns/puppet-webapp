# == Class: webapp
#
define webapp::python (
  $system_packages     = [],
  $pip_packages        = [],
  $git_source          = undef,
  $git_revision        = 'master',
  $git_user            = 'root',
  $domain_name         = undef,
  $wsgi_script_aliases = 'webapp.wsgi',
  $cron_jobs           = {},
) {
  validate_array($system_packages)
  validate_array($pip_packages)
  if ! $git_source {
    fail("you must specify git_source for webapp::define[${name}]")
  }
  validate_string($git_source)
  validate_string($git_revision)
  validate_string($git_user)
  if ! $domain_name {
    fail("you must specify domain_name for webapp::define[${name}]")
  }
  validate_string($domain_name)
  validate_string($wsgi_script_aliases)
  validate_hash($cron_jobs)

  $approot = "${webapp::web_root}/${name}"

  ensure_packages(['git'])
  ensure_packages($system_packages)

  vcsrepo { $approot:
    ensure   => latest,
    provider => git,
    user     => $git_user,
    revision => $git_revision,
    source   => $git_source,
    require  => Package[$system_packages],
  }
  python::virtualenv {$approot:
    ensure  => present,
    path    => ['/bin', '/usr/bin', '/usr/sbin', '/usr/local/bin'],
    owner   => $git_user,
    require => Vcsrepo[$approot],
  }
  ensure_resource('python::pip', $pip_packages,
      { 'virtualenv' => $approot, require => Vcsrepo[$approot] })

  apache::vhost { $domain_name:
    servername          => $domain_name,
    docroot             => "${approot}/",
    wsgi_daemon_process => "${name}-wsgi-webapp",
    port                => 80,
    wsgi_script_aliases => {
      '/' => "${approot}/${wsgi_script_aliases}"
    },
    require             => Vcsrepo[$approot];
  }
  create_resources(cron, $cron_jobs)
}
