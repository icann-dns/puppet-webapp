# define webapp::python::pip
#
define webapp::python::pip (
  $require     = undef,
  $virtual_env = undef,
  $approot     = undef,
) {
  validate_string($require)
  validate_string($virtual_env)
  python::pip { "${virtual_env}-${name}":
    virtualenv => $approot,
    require    => $require,
    pkgname    => $name,
  }

}

