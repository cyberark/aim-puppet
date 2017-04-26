# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# ------------------------------------------------------------------------------------------


module Puppet::Parser::Functions
    newfunction(:deleteenvironment, :type => :rvalue) do |args|
        require_relative 'CreateEnv.rb'
        require 'securerandom'

        createEnvInfo = args[0]
        user_and_pwd = args[1]
        FullPathLogFilename=args[2]
       
        #delete the environment in vault
        ce = CreateEnv.new(createEnvInfo, user_and_pwd, FullPathLogFilename)
        res = ce.deleteEnv()
        return true
    end
end

