# This is an autogenerated function, ported from the original legacy version.
# It /should work/ as is, but will not have all the benefits of the modern
# function API. You should see the function docs to learn how to add function
# signatures for type safety and to document this function using puppet-strings.
#
# https://puppet.com/docs/puppet/latest/custom_functions_ruby.html
#
# ---- original file header ----
# frozen_string_literal: true

# uniquepip_packages.rb
#
# ---- original file header ----
#
# @summary
#   This function converts an array of pip package names to a hash of python::pip objects to be used with create_resources()
#
#*Examples:*
#    flatten(['pip-package1', 'pip-packae2'], 'exmple', 'File["bla"]')
#Would return: {
#  'example-pip-package1' => {
#    virtual => 'example',
#    pkgname => 'pip-package1',
#    require => File["bla"],
#    }
#  }
#
#
Puppet::Functions.create_function(:'webapp::unique_pip_packages') do
  # @param arguments
  #   The original array of arguments. Port this to individually managed params
  #   to get the full benefit of the modern function API.
  #
  # @return [Data type]
  #   Describe what the function returns here
  #
  dispatch :default_impl do
    # Call the method named 'default_impl' when this is matched
    # Port this to match individual params for better type safety
    repeated_param 'Any', :arguments
  end


  def default_impl(*arguments)
    
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