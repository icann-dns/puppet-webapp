# frozen_string_literal: true

require 'spec_helper'

describe 'webapp' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      # web_root: $webapp::params::web_root,
      # python_apps: {},
    }
  end

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
        it { is_expected.to contain_file('/srv/www').with_ensure('directory') }
        it { is_expected.to contain_class('Webapp') }
        it { is_expected.to contain_class('Webapp::Params') }
      end

      describe 'Change Defaults' do
        context 'web_root' do
          before { params.merge!(web_root: '/foo') }
          it { is_expected.to compile }
          it { is_expected.to contain_file('/foo').with_ensure('directory') }
        end
        context 'python_apps' do
          before do
            params.merge!(
              python_apps: {
                'test_app' => { 'git_source' => 'test', 'domain_name' => 'test' }
              }
            )
          end
          it { is_expected.to compile }
          it { is_expected.to contain_webapp__python('test_app') }
        end
        context 'html_apps' do
          before do
            params.merge!(
              html_apps: {
                'test_app' => { 'git_source' => 'test', 'domain_name' => 'test' }
              }
            )
          end
          it { is_expected.to compile }
          it { is_expected.to contain_webapp__html('test_app') }
        end
      end

      # You will have to correct any values that should be bool
      describe 'check bad type' do
        context 'web_root' do
          before { params.merge!(web_root: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'python_apps' do
          before { params.merge!(python_apps: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'html_apps' do
          before { params.merge!(html_apps: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
