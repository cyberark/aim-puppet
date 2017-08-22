# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_credential - it retrieves a credential from CyberArk Vault. It uses CyberArk
#                           Java Password SDK, passing the criteria based on parameters.
#
#  * :cyberark_random_password - Returns a random password generated using SecureRandom
#                                function.
#
#  * :cyberark_new_session_id - Returns a session by increasing the store value in file
#                               /tmp/counter_aim_sessionid; it uses file lock mechanism to
#                               achieve atomic sessionId allocation.
#
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
                @logger.debug("GetPass() : passRequest.setQuery(\"" + @pwdAdminInfo["query"] + "\")");
                passRequest.setQuery(@pwdAdminInfo["query"])
            end

            password = Java::Javapasswordsdk::PSDKPassword
            password = Java::Javapasswordsdk::PasswordSDK::getPassword (passRequest)

            @logger.debug(" Result = " + password.getUserName());

            return [password.getUserName(), password.getContent()]
        rescue Exception => e
            @logger.error("GetPass() : Got Exception on call to GetPassword :" + e.message )
            raise e
        end
    end

    newfunction(:cyberark_random_password, :type => :rvalue) do |args|
        require 'securerandom'
        return "X_"+SecureRandom.hex(10)
    end

    newfunction(:cyberark_new_session_id, :type => :rvalue) do |args|

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
