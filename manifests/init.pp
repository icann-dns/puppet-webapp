# @summary wrapper class to create vhosts
# @param web_root the main web root
# @param python_apps a hash of webapp::python resources to create
# @param html_apps a hash of webapp::html resources to create
class webapp (
  Stdlib::Absolutepath $web_root    = '/srv/www',
  Hash                 $python_apps = {},
  Hash                 $html_apps   = {},
) {
  include apache
  ensure_resource('file', $web_root, { 'ensure' => 'directory', mode => '0777' })
  $python_apps.each |$title, $params| {
    webapp::python { $title:
      * => $params,
    }
  }
  $html_apps.each |$title, $params| {
    webapp::html { $title:
      * => $params,
    }
  }
}
