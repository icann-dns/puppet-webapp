# == Class: webapp
#
class webapp (
  $web_root        = $::webapp::params::web_root,
  $python_apps = {},
) inherits webapp::params {

  validate_absolute_path($web_root)
  validate_hash($python_apps)

  ensure_resource('file', $web_root, { 'ensure' => 'directory' })
  create_resources(webapp::python, $python_apps)
  include apache

}
