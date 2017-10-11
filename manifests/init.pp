# == Class: webapp
#
class webapp (
  Stdlib::Absolutepath $web_root    = $::webapp::params::web_root,
  Hash                 $python_apps = {},
  Hash                 $html_apps   = {},
) inherits webapp::params {

  include ::apache
  ensure_resource('file', $web_root, { 'ensure' => 'directory', mode => '0777' })
  create_resources(webapp::python, $python_apps)
  create_resources(webapp::html, $html_apps)

}
