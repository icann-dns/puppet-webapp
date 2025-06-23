# @summary resource to create simple python web sites
# @param domain_name the domain name of the website
# @param system_packages A list if system packages to install
# @param pip_packages A list if pip packages to install
# @param git_source The git source location of the site
# @param ssl_cert The ssl cert to use is ssl is in user
# @param ssl_key The ssl key to use is ssl is in user
# @param ssl_chain The ssl chain to use is ssl is in user
# @param init_scripts a lit of init scripts e.g. db_create screips to run after install
# @param git_revision The git revision to use
# @param user The user to use
# @param git_user The user to use for git operations
# @param wsgi_script_aliases the file used for the wsgi script
# @param docroot_subfolder The doc root subfolder
# @param use_ssl If we use ssl
# @param log_dir
# @param options Additional vhost options
# @param cron_jobs A list f cron jobs for the site
define webapp::python (
  String $domain_name,
  String $git_source,
  Array[String] $system_packages               = [],
  Array[String] $pip_packages                  = [],
  Optional[Stdlib::Absolutepath] $ssl_cert     = undef,
  Optional[Stdlib::Absolutepath] $ssl_key      = undef,
  Optional[Stdlib::Absolutepath] $ssl_chain    = undef,
  Hash[String, String]           $init_scripts = {},
  String $git_revision                         = 'master',
  String $user                                 = 'www-data',
  String $git_user                             = $user,
  Stdlib::Absolutepath $docroot_subfolder      = '/',
  String $wsgi_script_aliases                  = 'webapp.wsgi',
  Boolean $use_ssl                             = false,
  Optional[Stdlib::Unixpath] $log_dir          = undef,
  Array[String] $options                       = ['Indexes','FollowSymLinks','MultiViews'],
  Hash $cron_jobs                              = {},
) {
  if $use_ssl {
    unless $ssl_cert and $ssl_key {
      fail('you must specify ssl_cert and ssl_key if use_ssl==true')
    }
  }
  $approot = "${webapp::web_root}/${name}"

  ensure_packages(['git'])
  ensure_packages($system_packages)

  include apache::mod::wsgi

  if $log_dir {
    file { $log_dir:
      ensure => directory,
      owner  => $user,
      group  => $user,
    }
  }

  vcsrepo { $approot:
    ensure   => latest,
    provider => git,
    user     => $user,
    revision => $git_revision,
    source   => $git_source,
    require  => Package[$system_packages],
    notify   => Service['httpd'],
  }
  $venv_dir = "${approot}/venv"
  python::pyvenv { $venv_dir:
    ensure  => present,
    owner   => $user,
    require => Vcsrepo[$approot],
    notify  => Service['httpd'],
  }
  if $pip_packages {
    $pip_packages_resources = unique_pip_packages($pip_packages, $venv_dir, Vcsrepo[$approot])
    create_resources(python::pip, $pip_packages_resources)
  }
  if !empty($init_scripts) {
    $init_scripts.each |$cmd, $creates| {
      exec { "${approot}/${cmd}":
        creates   => "${approot}/${creates}",
        cwd       => $approot,
        subscribe => Vcsrepo[$approot],
        require   => [
          Python::Pyvenv[$venv_dir],
          Python::Pip[$pip_packages_resources.keys()]
        ],
      }
    }
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
      wsgi_daemon_process         => {
        $name => {
          'user'        => $user,
          'python-home' => $venv_dir,
          'python-path' => $approot,
        },
      },
      wsgi_process_group          => $name,
      wsgi_script_aliases         => {
        '/'           => "${approot}/${wsgi_script_aliases}",
      },
      options                     => $options,
      manage_docroot              => false,
      require                     => Vcsrepo[$approot],
    }
  } else {
    apache::vhost { $domain_name:
      servername                  => $domain_name,
      docroot                     => "${approot}${docroot_subfolder}",
      wsgi_daemon_process         => {
        $name => {
          'user'        => $user,
          'python-home' => $venv_dir,
        },
      },
      wsgi_process_group          => $name,
      port                        => 80,
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
