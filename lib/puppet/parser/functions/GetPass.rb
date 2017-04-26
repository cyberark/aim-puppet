# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
#    
#
#    A Jruby implementation of CyberArk AIM for Puppet integration
#    Given <appId,safe,Object> retrieves for object via CyberArk AIM Java SDK.
# ------------------------------------------------------------------------------------------

#Including Jruby Java interface and loading CyberArk Jar
include Java
require '/opt/CARKaim/sdk/javapasswordsdk.jar'
require 'logger'

#Importing Required Java classes into script
java_import 'javapasswordsdk.PSDKPassword'
java_import 'javapasswordsdk.PSDKPasswordRequest'
java_import 'javapasswordsdk.exceptions.PSDKException'

#class for handling request
class GetPass

       
    #Given <appId,safe,object>, Call CyberArk JAVA SDK. On returned object, select which attribute to return
    def PassGrab(pwdAdminInfo, fullPathLogFilename)
      @pwdAdminInfo = pwdAdminInfo
      
      if fullPathLogFilename == ""
        @logger = Logger.new(STDOUT)      
      else
        @logger = Logger.new(fullPathLogFilename)      
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
  end
      


