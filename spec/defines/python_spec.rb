require 'spec_helper'
require 'shared_contexts'

describe 'webapp::python' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  let(:title) { 'test_app' }
  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #system_packages: ["git"],
      #pip_packages: [],
      git_source: 'git@git.example.com:root/example.git',
      #git_revision: "master",
      #git_user: "root",
      domain_name: 'test.example.com',
      #wsgi_script_aliases: "webapp.wsgi",
      #cron_jobs: {},
    }
  end
  let(:pre_condition) { "class {'::webapp':}" }
  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        # add these two lines in a single test block to enable puppet and hiera debug mode
        # Puppet::Util::Log.level = :debug
        # Puppet::Util::Log.newdestination(:console)
        it do
          is_expected.to compile.with_all_deps
        end

        it do
          is_expected.to contain_vcsrepo('/srv/www/test_app')
            .with(
              'ensure'   => 'latest',
              'provider' => 'git',
              'revision' => 'master',
              'source'   => 'git@git.example.com:root/example.git',
              'user'     => 'root'
            )
        end
        it do
          is_expected.to contain_python__virtualenv('/srv/www/test_app')
            .with(
              'ensure'  => 'present',
              'owner'   => 'root',
              'require' => 'Vcsrepo[/srv/www/test_app]'
            )
        end
        it do
          is_expected.to contain_apache__vhost('test.example.com')
            .with(
              'docroot'             => '/srv/www/test_app/',
              'port'                => '80',
              'require'             => 'Vcsrepo[/srv/www/test_app]',
              'servername'          => 'test.example.com',
              'wsgi_daemon_process' => 'test_app-wsgi-webapp',
              'wsgi_script_aliases' => /webapp.wsgi/
            )
        end
        it { is_expected.to_not contain_apache__vhost('test.example.com-redirect') }
        it { is_expected.to_not contain_apache__vhost('test.example.com-ssl') }
      end

      describe 'Change Defaults' do
        context 'system_packages' do
          before { params.merge!( system_packages: ['git', 'curl'] ) }
          it { is_expected.to compile }
          it {is_expected.to contain_package('git') }
          it {is_expected.to contain_package('curl') }
        end
        context 'pip_packages' do
          before { params.merge!( pip_packages: ['Flask'] ) }
          it { is_expected.to compile }
          it { is_expected.to contain_python__pip('/srv/www/test_app-Flask') }
        end
        context 'git_source' do
          before { params.merge!( git_source: 'git@git.example.com:foo/bar.git' ) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app')
              .with(
                'ensure'   => 'latest',
                'provider' => 'git',
                'revision' => 'master',
                'source'   => 'git@git.example.com:foo/bar.git',
                'user'     => 'root'
              )
          end
        end
        context 'git_revision' do
          before { params.merge!( git_revision: 'foobar' ) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app')
              .with(
                'ensure'   => 'latest',
                'provider' => 'git',
                'revision' => 'foobar',
                'source'   => 'git@git.example.com:root/example.git',
                'user'     => 'root'
              )
          end
        end
        context 'git_user' do
          before { params.merge!( git_user: 'foobar' ) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app')
              .with(
                'ensure'   => 'latest',
                'provider' => 'git',
                'revision' => 'master',
                'source'   => 'git@git.example.com:root/example.git',
                'user'     => 'foobar'
              )
          end
        end
        context 'domain_name' do
          before { params.merge!( domain_name: 'foo.example.com' ) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_apache__vhost('foo.example.com')
              .with(
                'docroot'             => '/srv/www/test_app/',
                'port'                => '80',
                'require'             => 'Vcsrepo[/srv/www/test_app]',
                'servername'          => 'foo.example.com',
                'wsgi_daemon_process' => 'test_app-wsgi-webapp',
              )
          end
        end
        context 'wsgi_script_aliases' do
          before { params.merge!( wsgi_script_aliases: 'foobar' ) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apache__vhost('test.example.com')
              .with(
                'docroot'             => '/srv/www/test_app/',
                'port'                => '80',
                'require'             => 'Vcsrepo[/srv/www/test_app]',
                'servername'          => 'test.example.com',
                'wsgi_daemon_process' => 'test_app-wsgi-webapp',
                'wsgi_script_aliases' => /foobar/
              )
          end
        end
        context 'use ssl' do
          before { params.merge!( 
              use_ssl:  true,
              ssl_cert: '/foo.cert',
              ssl_key:  '/foo.key',
          ) }
          it { is_expected.to compile }
          it { is_expected.to_not contain_apache__vhost('test.example.com') }
          it do
            is_expected.to contain_apache__vhost('test.example.com-redirect')
              .with(
                'docroot'         => '/srv/www/test_app/',
                'port'            => '80',
                'require'         => 'Vcsrepo[/srv/www/test_app]',
                'servername'      => 'test.example.com',
                'redirect_status' => 'permanent',
                'redirect_dest'   => 'https://test.example.com/',
              )
          end
          it do
            is_expected.to contain_apache__vhost('test.example.com-ssl')
              .with(
                'docroot'             => '/srv/www/test_app/',
                'port'                => '443',
                'require'             => 'Vcsrepo[/srv/www/test_app]',
                'servername'          => 'test.example.com',
                'wsgi_daemon_process' => 'test_app-wsgi-webapp',
                'wsgi_script_aliases' => /webapp.wsgi/,
                'ssl'                 => 'true',
                'ssl_cert'            => '/foo.cert',
                'ssl_key'             => '/foo.key',
              )
          end
        end
        context 'cron_jobs' do
          before { params.merge!( cron_jobs: {} ) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'system_packages' do
          before { params.merge!( system_packages: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'pip_packages' do
          before { params.merge!( pip_packages: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_source' do
          before { params.merge!( git_source: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_revision' do
          before { params.merge!( git_revision: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_user' do
          before { params.merge!( git_user: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'domain_name' do
          before { params.merge!( domain_name: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'wsgi_script_aliases' do
          before { params.merge!( wsgi_script_aliases: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'cron_jobs' do
          before { params.merge!( cron_jobs: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use_ssl' do
          before { params.merge!( use_ssl: 'foobar' ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no certs or key' do
          before { params.merge!( use_ssl: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no  key' do
          before { params.merge!( 
              use_ssl: true ,
              ssl_cert: '/foo.cert',
          ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no cert' do
          before { params.merge!( 
              use_ssl: true ,
              ssl_key: '/foo.cert',
          ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssl_cert' do
          before { params.merge!( use_ssl: true, ssl_cert: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssl_key' do
          before { params.merge!( use_ssl: true, ssl_key: true ) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
