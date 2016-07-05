# == Class: webapp
#
class webapp (
  $web_root    = $::webapp::params::web_root,
  $python_apps = {},
  $html_apps   = {},
) inherits webapp::params {

  validate_absolute_path($web_root)
  validate_hash($python_apps)
  validate_hash($html_apps)

  include apache
  ensure_resource('file', $web_root, { 'ensure' => 'directory', mode => '0777' })
  create_resources(webapp::python, $python_apps)
  create_resources(webapp::html, $html_apps)

}
