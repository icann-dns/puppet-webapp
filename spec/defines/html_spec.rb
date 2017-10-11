# frozen_string_literal: true

require 'spec_helper'

describe 'webapp::html' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_app' }
  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # system_packages: ["git"],
      # pip_packages: [],
      git_source: 'git@git.example.com:root/example.git',
      # git_revision: "master",
      # user: "www-data",
      domain_name: 'test.example.com',
      # docroot_subfolder: '/'
      # wsgi_script_aliases: "webapp.wsgi",
      # options: ['Indexes','FollowSymLinks','MultiViews']
      # cron_jobs: {},
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
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_vcsrepo('/srv/www/test_app').with(
            ensure: 'latest',
            provider: 'git',
            revision: 'master',
            source: 'git@git.example.com:root/example.git',
            user: 'www-data'
          )
        end
        it do
          is_expected.to contain_apache__vhost('test.example.com').with(
            docroot: '/srv/www/test_app/',
            port: '80',
            servername: 'test.example.com',
            options: %w[Indexes FollowSymLinks MultiViews]
          )
        end
        it { is_expected.not_to contain_apache__vhost('test.example.com-redirect') }
        it { is_expected.not_to contain_apache__vhost('test.example.com-ssl') }
      end

      describe 'Change Defaults' do
        context 'system_packages' do
          before { params.merge!(system_packages: %w[git curl]) }
          it { is_expected.to compile }
          it { is_expected.to contain_package('git') }
          it { is_expected.to contain_package('curl') }
        end
        context 'git_source' do
          before { params.merge!(git_source: 'git@git.example.com:foo/bar.git') }
          it { is_expected.to compile }
          it { is_expected.not_to contain_file('/srv/www/test_app') }
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'master',
              source: 'git@git.example.com:foo/bar.git',
              user: 'www-data'
            )
          end
        end
        context 'puppet_source' do
          before do
            params.merge!(git_source: :undef, puppet_source: 'puppet:///foo')
          end
          it { is_expected.to compile }
          it { is_expected.not_to contain_vcsrepo('/srv/www/test_app') }
          it do
            is_expected.to contain_file('/srv/www/test_app').with(
              source: 'puppet:///foo',
              recurse: true
            )
          end
        end
        context 'git_revision' do
          before { params.merge!(git_revision: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'foobar',
              source: 'git@git.example.com:root/example.git',
              user: 'www-data'
            )
          end
        end
        context 'user' do
          before { params.merge!(user: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_vcsrepo('/srv/www/test_app').with(
              ensure: 'latest',
              provider: 'git',
              revision: 'master',
              source: 'git@git.example.com:root/example.git',
              user: 'foobar'
            )
          end
        end
        context 'domain_name' do
          before { params.merge!(domain_name: 'foo.example.com') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apache__vhost('foo.example.com').with(
              docroot: '/srv/www/test_app/',
              port: '80',
              servername: 'foo.example.com'
            )
          end
        end
        context 'docroot_subfolder' do
          before { params.merge!(docroot_subfolder: '/foo') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apache__vhost('test.example.com').with(
              docroot: '/srv/www/test_app/foo'
            )
          end
        end
        context 'use ssl' do
          before do
            params.merge!(
              use_ssl:  true,
              ssl_cert: '/foo.cert',
              ssl_key:  '/foo.key'
            )
          end
          it { is_expected.to compile }
          it { is_expected.not_to contain_apache__vhost('test.example.com') }
          it do
            is_expected.to contain_apache__vhost('test.example.com-redirect').with(
              docroot: '/srv/www/test_app/',
              port: '80',
              servername: 'test.example.com',
              redirect_status: 'permanent',
              redirect_dest: 'https://test.example.com/'
            )
          end
          it do
            is_expected.to contain_apache__vhost('test.example.com-ssl').with(
              docroot: '/srv/www/test_app/',
              port: '443',
              servername: 'test.example.com',
              ssl: 'true',
              ssl_cert: '/foo.cert',
              ssl_key: '/foo.key'
            )
          end
        end
        context 'options' do
          before { params.merge!(options: ['foobar']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_apache__vhost('test.example.com').with(
              docroot: '/srv/www/test_app/',
              port: '80',
              options: ['foobar']
            )
          end
        end
      end
      describe 'check bad type' do
        context 'system_packages' do
          before { params.merge!(system_packages: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_source' do
          before { params.merge!(git_source: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'puppet_source' do
          before { params.merge!(git_source: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_source and puppet_source' do
          before { params.merge!(git_source: 'foo', puppet_source: 'bar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'no git_source and no puppet_source' do
          before { params.merge!(git_source: :undef, puppet_source: :undef) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'git_revision' do
          before { params.merge!(git_revision: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'user' do
          before { params.merge!(user: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'domain_name' do
          before { params.merge!(domain_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'docroot_subfolder' do
          before { params.merge!(docroot_subfolder: 'asd') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'docroot_subfolder' do
          before { params.merge!(docroot_subfolder: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'cron_jobs' do
          before { params.merge!(cron_jobs: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use_ssl' do
          before { params.merge!(use_ssl: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no certs or key' do
          before { params.merge!(use_ssl: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no  key' do
          before do
            params.merge!(
              use_ssl: true,
              ssl_cert: '/foo.cert'
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'use ssl no cert' do
          before do
            params.merge!(
              use_ssl: true,
              ssl_key: '/foo.cert'
            )
          end
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssl_cert' do
          before { params.merge!(use_ssl: true, ssl_cert: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'ssl_key' do
          before { params.merge!(use_ssl: true, ssl_key: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'options' do
          before { params.merge!(options: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
