# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# This function is called from init.pp, and used merely as wrapper to call object CreateEnv.
# CreateEnv object, in turn, creates the specified envrionment of the deployed provider.
# ------------------------------------------------------------------------------------------

module Puppet::Parser::Functions
   newfunction(:createenvironment, :type => :rvalue) do |args|
        require_relative 'CreateEnv.rb'
        require 'securerandom'

        createEnvInfo = args[0]
        user_and_pwd = args[1]
        FullPathLogFilename=args[2]
       
       ProvUserPwd="X_"+SecureRandom.hex(10)               # should be aligned with password policy
       
       #create environment in the vault
       ce = CreateEnv.new(createEnvInfo, user_and_pwd, FullPathLogFilename)
       res = ce.create(ProvUserPwd)
       if res != true
          #raise Puppet::ParseError, "Failed to Create Environment. Check logs:" + FullPathLogFilename
          return ""
       end

       return ProvUserPwd
   end
end
