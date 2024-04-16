# @summary resource to create simple html web sites
#
# @param domain_name the domain name of the website
# @param system_packages A list if system packages to install
# @param puppet_source The puppet source location of the site
# @param git_source The git source location of the site
# @param ssl_cert The ssl cert to use is ssl is in user
# @param ssl_key The ssl key to use is ssl is in user
# @param ssl_chain The ssl chain to use is ssl is in user
# @param git_revision The git revision to use
# @param user The user to use
# @param docroot_subfolder The doc root subfolder
# @param use_ssl If we use ssl
# @param options Additional vhost options
# @param cron_jobs A list f cron jobs for the site
define webapp::html (
  String $domain_name,
  Array[String] $system_packages            = [],
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
  $cron_jobs.each |$title, $params| {
    cron { $title:
      * => $params,
    }
  }
}
