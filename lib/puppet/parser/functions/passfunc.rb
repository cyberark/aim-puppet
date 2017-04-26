# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# This function is called from init.pp to retrieve the administrative credentials
# from the preinstalled provider. The credentials will be used to create environment of 
# the deployed provider (through REST commands to PVWA). 
# The function calls object GetPass  with the given query
# ------------------------------------------------------------------------------------------

module Puppet::Parser::Functions
    newfunction(:passfunc, :type => :rvalue) do |args|
        require_relative 'GetPass.rb'
        pwdAdminInfo = args[0]
        fullLogFileName = args[1]
        
        passrequest = GetPass.new().PassGrab(pwdAdminInfo, fullLogFileName)
  end
end

