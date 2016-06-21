#
# unique_pip_packages.rb
#
module Puppet::Parser::Functions
  newfunction(:unique_pip_packages, :type => :rvalue, :doc => <<-EOS
This function a uniqu has to be used tith python::pip its main purpose is to allow one to install a package in multible virtual envs

*Examples:*
    flatten(['pip-package1', 'pip-packae2'], 'exmple', 'File["bla"]')
Would return: { 
  'example-pip-package1' => { 
    virtual => 'example',
    pkgname => 'pip-package1',
    require => File["bla"],
    }
  }
    EOS
  ) do |arguments|
    raise(Puppet::ParseError, "flatten(): Wrong number of arguments " +
          "given (#{arguments.size} for 1)") if arguments.size != 3
    _pip_packages = arguments[0]
    _virtualenv   = arguments[1]
    _require      = arguments[2]
    unless _pip_packages.is_a?(Array)
      raise(Puppet::ParseError, 'unique_pip_packages(): Requires array to work with')
    end
    pip_defines = {}
    _pip_packages.each do |_pip_package|
      pip_defines["#{_virtualenv}-#{_pip_packages}"] = {
        'virtualenv' => _virtualenv,
        'pkgname' => _pip_packages,
        'require' => _require,
      }
    end
    return pip_defines
  end
end
