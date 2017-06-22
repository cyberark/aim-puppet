# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# This function is called from init.pp to retrieve the administrative credentials
# from the preinstalled provider. The credentials will be used to create environment of
# the deployed provider (through REST commands to PVWA).
# The function calls object GetPass  with the given query
# ------------------------------------------------------------------------------------------

#Including Jruby Java interface and loading CyberArk Jar
include Java
require '/opt/CARKaim/sdk/javapasswordsdk.jar'
require 'logger'

#Importing Required Java classes into script
java_import 'javapasswordsdk.PSDKPassword'
java_import 'javapasswordsdk.PSDKPasswordRequest'
java_import 'javapasswordsdk.exceptions.PSDKException'


module Puppet::Parser::Functions

    newfunction(:cyberark_credential, :type => :rvalue) do |args|
        pwdAdminInfo = args[0]
        fullLogFileName = args[1]

        @pwdAdminInfo = pwdAdminInfo

        if fullLogFileName == ""
            @logger = Logger.new(STDOUT)
        else
            @logger = Logger.new(fullLogFileName)
        end

        @logger.info("Retrieve administrative credential for deployment via Javapasswordsdk with the following query:")

        begin
            passRequest = Java::Javapasswordsdk::PSDKPasswordRequest::new()
            if @pwdAdminInfo.key? "safe"
                @logger.debug("GetPass() : passRequest.setSafe(\"" + @pwdAdminInfo["safe"] + "\")");
                passRequest.setSafe(@pwdAdminInfo["safe"])
            end
            if @pwdAdminInfo.key? "folder"
                @logger.debug("GetPass() : passRequest.setFolder(\"" + @pwdAdminInfo["folder"] + "\")");
                passRequest.setFolder(@pwdAdminInfo["folder"])
            end
            if @pwdAdminInfo.key? "appId"
                @logger.debug("GetPass() : passRequest.setAppID(\"" + @pwdAdminInfo["appId"] + "\")");
                passRequest.setAppID(@pwdAdminInfo["appId"])
            end
            if @pwdAdminInfo.key? "object"
                @logger.debug("GetPass() : passRequest.setObject(\"" + @pwdAdminInfo["object"] + "\")");
                passRequest.setObject(@pwdAdminInfo["object"])
            end
            if @pwdAdminInfo.key? "query"
                @logger.debug("GetPass() : passRequest.setObject(\"" + @pwdAdminInfo["query"] + "\")");
                passRequest.setQuery(@pwdAdminInfo["query"])
            end

            password = Java::Javapasswordsdk::PSDKPassword
            password = Java::Javapasswordsdk::PasswordSDK::getPassword (passRequest)

            return [password.getUserName(), password.getContent()]
        rescue Exception => e
            @logger.error("GetPass() : Got Exception on call to GetPassword :" + e.message )
            raise e
        end
    end

    newfunction(:cyberark_random_password, :type => :rvalue) do
        require 'securerandom'
        return "X_"+SecureRandom.hex(10)
    end

    newfunction(:cyberark_new_session_id, :type => :rvalue) do

        filenameCounterSessionId = "/tmp/counter_aim_sessionid"

        sid = 0

        # Use file lock mechanism to achieve atomic sessionId allocation. Effective range is 1-100
        # (Some OSs might not support flock)
        File.open(filenameCounterSessionId, File::RDWR|File::CREAT, 0644) {|f|
            f.flock(File::LOCK_EX)
            sid = f.read.to_i + 1
            if sid == 100
                sid = 1
            end
            f.rewind
            f.write("#{sid}\n")
            f.flush
            f.truncate(f.pos)
        }
        return sid
    end


end
