# frozen_string_literal: true

# uniquepip_packages.rb
#
module Puppet::Parser::Functions
  newfunction(
    :unique_pip_packages, type: :rvalue, doc: <<-EOS
This function converts an array of pip package names to a hash of python::pip objects to be used with create_resources()

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
    unless arguments.size == 3
      raise(
        Puppet::ParseError,
        "flatten(): Wrong number of arguments given (#{arguments.size} for 1)"
      )
    end
    pip_packages = arguments[0]
    virtualenv   = arguments[1]
    type_require = arguments[2]
    unless pip_packages.is_a?(Array)
      raise(
        Puppet::ParseError,
        'uniquepip_packages(): Requires array to work with'
      )
    end
    pip_defines = {}
    pip_packages.each do |pip_package|
      pip_defines["#{virtualenv}-#{pip_package}"] = {
        'virtualenv' => virtualenv,
        'pkgname' => pip_package,
        'require' => type_require
      }
    end
    return pip_defines
  end
end
