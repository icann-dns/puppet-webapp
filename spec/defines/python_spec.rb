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
      git_source: 'git@git.example.com:www-data/example.git',
      #git_revision: "master",
      #user: "www-data",
      domain_name: 'test.example.com',
      #docwww-data_subfolder: '/'
      #wsgi_script_aliases: "webapp.wsgi",
      #cron_jobs: {},
    }
  end
  let(:pre_condition) { "class {'::webapp':}" }
  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
end
