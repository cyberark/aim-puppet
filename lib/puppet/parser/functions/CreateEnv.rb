# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
#  
#
#  Creates the Vault environment for the deployed Provider by using PVWA REST services.
# ------------------------------------------------------------------------------------------

require 'pp'
require 'logger'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'


class CreateEnv

    def initialize(createEnvInfo, user_and_pwd, fullPathLogFilename) 
      @PimServices            = "/PasswordVault/WebServices/PIMServices.svc"

      @createEnvInfo          = createEnvInfo      
      @http_host              = @createEnvInfo["http_pvwa"] 
      @ProviderUsername       = @createEnvInfo["cp_user"]
      @AdminUsername          = user_and_pwd[0]
      @AdminPwd               = user_and_pwd[1]

      @sessionToken           = ""
      @isUserAdded            = false
      @uri                    = URI.parse(@http_host)
      @httpInstance           = Net::HTTP.new(@uri.host, @uri.port)      
      @flowName               ="CreateEnv"

      if fullPathLogFilename == ""
        @logger = Logger.new(STDOUT)      
      else
        @logger = Logger.new(fullPathLogFilename)      
      end
      
      @logger.debug(@flowName + "() : Initializing new object CreateEnv")
      
      if @uri.scheme == "https"

        @httpInstance.use_ssl = true
        @httpInstance.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @httpInstance.cert_store = OpenSSL::X509::Store.new
        @httpInstance.cert_store.set_default_paths
        if @createEnvInfo["cacert_file"] != ""
            @httpInstance.cert_store.add_file @createEnvInfo["cacert_file"]
        end
      end
    end
    
    ###########################################################################################
    # Description:    Creates the envrionment in vault as specified through REST commands to PVWA. 
    # Arguments:      ProviderPwd - The new user password of the deployed Provider
    def create(providerPwd)

        @AddToGroups            = @createEnvInfo["add_prov_user_to_groups"]
        @UserLocation           = @createEnvInfo["location"]
        @ConfigurationSafe      = @createEnvInfo["cp_safe_config"]
        @ProviderPwd            = providerPwd
        @flowName = "CreateEnv"

        @logger.debug(@flowName + "() : ---------------------------------------")
        @logger.debug(@flowName + "() : ProviderUsername=" + @ProviderUsername)
        @logger.debug(@flowName + "() : AddToGroups="+       @AddToGroups)
        @logger.debug(@flowName + "() : UserLocation="+      @UserLocation)
        @logger.debug(@flowName + "() : ConfigurationSafe="+ @ConfigurationSafe)
        @logger.debug(@flowName + "() : ---------------------------------------")

        begin

            # create Provider environment in vault
            res = innerCreate()

            # If create env passed fine, return true
            if res == true
                return true
            end

            # Returned false
            raise ArgumentError, "Failed to create Env"

        rescue Exception => e
            @logger.error(@flowName + "() : Exception: " +  e.message )
            if @isUserAdded == true
                deleteEnv()
            end
            raise e
        end

        # never reach this return
        return true
    end

    ###########################################################################################
    # Description:    Open a new session if session is already closed. In the end the session is 
    #                 closed(in either case).
    def deleteEnv()
        
        @flowName = "DeleteEnv"
        
        res = logon()
        if res != true
            @logger.error(@flowName + "() : PVWA logon failed")
            # return. Nothing we can do if there is no session with Vault...
            return false
        end 
        
        res = removeUser()
        if res != true
            @logger.error(@flowName + "() : Failed to remove user" + @ProviderUsername)
            # don't return, continue to logoff the session
        end 
        
        res = logoff()
        if res != true
            @logger.error(@flowName + "() : PVWA logoff failed")
            return false
        end 
        
        @logger.info(@flowName + "() : Vault environment has been removed successfully")
        return true
    end    
    
private

    ###########################################################################################
    def innerCreate()
        res = logon()
        if res != true
            @logger.error(@flowName + "() : PVWA logon failed")
            return false
        end 
        
        res = addUser()
        if res != true
            @logger.error(@flowName + "() : Failed to add user " + @ProviderUsername)
            return false
        end 
        
        res = AddSafeMember()
        if res != true
            @logger.error(@flowName + "() : Failed to add user " + @ProviderUsername + " as owner of safe " + @ConfigurationSafe)
            return false
        end 
        
        res = AddUserToGroups()
        if res != true
            @logger.error(@flowName + "() : Failed to add user " + @ProviderUsername + " to groups " + @AddToGroups)
            return false
        end 
        
        res = logoff()
        if res != true
            @logger.error(@flowName + "() : PVWA logoff failed")
            return false
        end 
        
        @logger.info(@flowName + "() : Vault environment has been created successfully")
        return true

    end

    ###########################################################################################    
    def getNewSessionId()
        
        filenameCounterSessionId = "/tmp/counter_aim_sessionid"
        
        sid = 0
        
        if @createEnvInfo.key? "sessionid"
            filenameCounterSessionId = @createEnvInfo["sessionid"]
        end
        
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
    
    ###########################################################################################    
    def logon()
        if @sessionToken != ""
            @logger.debug(@flowName + "() : PVWA logon is not required, using current session")
            return true
        end

        sessionId = getNewSessionId()
        
        @logger.info(@flowName + "() : Allocated session ID #" + sessionId.to_s + " for PVWA API")
        @logger.info(@flowName + "() : Creating new PVWA session. URL: " + @http_host)
        request = Net::HTTP::Post.new("/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon")
        request.add_field('Content-Type', 'application/json')

        request.body =  {'username' => @AdminUsername, 'password' => @AdminPwd, 'connectionNumber' => sessionId}.to_json
        response = @httpInstance.request(request)
        responseHash  = JSON.parse(response.body)
        if responseHash["ErrorCode"] != nil
            @logger.error(@flowName + "() : Received HTTP response: " + responseHash["ErrorCode"] + " - " + responseHash["ErrorMessage"])
            return false
        end

        # sessionToken
        if responseHash["CyberArkLogonResult"] == nil
            @logger.error(@flowName + "() : Received unexpected response format. Missing 'CyberArkLogonResult'")
            return false
        end

        @sessionToken = responseHash["CyberArkLogonResult"]
        @logger.info(@flowName + "() : Successfully received PVWA session token")
        return true
    end

    
    ###########################################################################################
    # Description:     Check if Provider user already exists in the vault
    def isUserExist()
        # Check first if user already exists
        request = Net::HTTP::Get.new(@PimServices + "/Users/" + @ProviderUsername)
        request.add_field('Content-Type', 'application/json')
        request.add_field('Authorization', @sessionToken)
        response = @httpInstance.request(request)
        responseHash = JSON.parse(response.body)
        
        if responseHash["AgentUser"] == nil
            return false
        else
            return true
        end
    end
    
    
    ###########################################################################################
    # Description:     Remove user (as part of rollback/uninstall flow)
    def removeUser()
        @logger.info(@flowName + "() : Trying to delete user '" + @ProviderUsername + "'")


        if isUserExist() == false
            @logger.info(@flowName + "() : User '" + @ProviderUsername + "' does not exist in the vault")
            return true
        else
            @logger.info(@flowName + "() : User '" + @ProviderUsername + "' exists in the vault. Sending Request to delete user")
        end

        # Delete user
        request = Net::HTTP::Delete.new(@PimServices + "/Users/" + @ProviderUsername)
        request.add_field('Content-Type', 'application/json')
        request.add_field('Authorization', @sessionToken)

        response = @httpInstance.request(request)        
        #pp response

        if response.code != "200"
            @logger.error(@flowName + "() : HTTP error in response: " + response.code)

        else
            @logger.info(@flowName + "() : User '" + @ProviderUsername + "' has been deleted successfully")
        end 

        return true
    end
    
    ###########################################################################################
    # Description:     This method adds a new user to the Vault.
    def addUser()
        @logger.info(@flowName + "() : Creating new user '" + @ProviderUsername + "'")

        if isUserExist() == true
            @logger.info(@flowName + "() : User '" + @ProviderUsername + "' already exists in the vault")
            return true
        end
        
        # Add new user
        request = Net::HTTP::Post.new(@PimServices + "/Users")
        request.add_field('Content-Type', 'application/json')
        request.add_field('Authorization', @sessionToken)
        
        request.body =  {
                'UserName'=>                         @ProviderUsername,
                'InitialPassword'=>                 @ProviderPwd,
                'ChangePasswordOnTheNextLogon'=>     false,
                'UserTypeName'=>                     'AppProvider',
                'Disabled'=>                         false,
                'Location'=>                         @UserLocation
            }.to_json
            

        response = @httpInstance.request(request)
        responseHash = JSON.parse(response.body)
        
        if responseHash["ErrorCode"] != nil
            @logger.error(@flowName + "() : Received response " + responseHash["ErrorCode"] + " - " + responseHash["ErrorMessage"])
            return false
        end    
        
        if responseHash["AgentUser"] == nil
            @logger.error(@flowName + "() : Received response is in unexpected format")
            return false
        end
        
        @isUserAdded = true
        return true
    end
    
    ###########################################################################################
    # Description: This method adds an existing user as a Safe member.
    #              The user with which this web service is run requires the 'Manage Safe Members' permission in the vault.
    def AddSafeMember()
        @logger.info(@flowName + "() : Adding user '" + @ProviderUsername + "' as owner of safe '" + @ConfigurationSafe + "'")

        # Add Safe Member
        request = Net::HTTP::Post.new(@PimServices + "/Safes/" + @ConfigurationSafe + "/Members")
        request.add_field('Content-Type', 'application/json')
        request.add_field('Authorization', @sessionToken)
        
        request.body = 
            {"member"=>
                {
                    "MemberName"=> @ProviderUsername,
                    "MembershipExpirationDate"=>"",
                    "Permissions"=>
                    [
                        {"Key"=>"UseAccounts","Value"=>true},
                        {"Key"=>"RetrieveAccounts","Value"=>true},
                        {"Key"=>"ListAccounts","Value"=>true},
                        {"Key"=>"AddAccounts","Value"=>false},
                        {"Key"=>"UpdateAccountContent","Value"=>false},
                        {"Key"=>"UpdateAccountProperties","Value"=>false},
                        {"Key"=>"InitiateCPMAccountManagementOperations","Value"=>false},
                        {"Key"=>"SpecifyNextAccountContent","Value"=>false},
                        {"Key"=>"RenameAccounts","Value"=>false},
                        {"Key"=>"DeleteAccounts","Value"=>false},
                        {"Key"=>"UnlockAccounts","Value"=>false},
                        {"Key"=>"ManageSafe","Value"=>false},
                        {"Key"=>"ManageSafeMembers","Value"=>false},
                        {"Key"=>"BackupSafe","Value"=>false},
                        {"Key"=>"ViewAuditLog","Value"=>true},
                        {"Key"=>"ViewSafeMembers","Value"=>true},
                        {"Key"=>"AccessWithoutConfirmation","Value"=>false},
                        {"Key"=>"CreateFolders","Value"=>false},
                        {"Key"=>"DeleteFolders","Value"=>false},
                        {"Key"=>"MoveAccountsAndFolders","Value"=>false},
                        {"Key"=>"RequestsAuthorizationLevel","Value"=>0}
                    ],
                    "SearchIn"=>"Vault"
                }
            }.to_json

        response = @httpInstance.request(request)

        if response.code == "201"
            @logger.info(@flowName + "() : User '" + @ProviderUsername + "' was successfully added as owner of safe '" + @ConfigurationSafe + "'")
            return true
        end            
        
        responseHash = JSON.parse(response.body)
        
        if responseHash["ErrorCode"] != nil
            @logger.error(@flowName + "() : Received reponse: " + responseHash["ErrorCode"] + " - " + responseHash["ErrorMessage"])
            return false
        end    
        
        return false
    end
    
    ###########################################################################################
    def AddUserToGroups()
        if @AddToGroups == ''
            @logger.info(@flowName + "() : Not adding user '" + @ProviderUsername + "' to a group, parameter 'AddToGroups' is not set")
            return true
        end
        
        groupsArray = @AddToGroups.split(":")
        groupsArray.each do |addToGroup|
            @logger.info(@flowName + "() : Adding user '" + @ProviderUsername + "' to group '" + addToGroup + "'")  

            # Add new user to group
            request = Net::HTTP::Post.new(@PimServices + "/Groups/" + addToGroup + "/Users")
            request.add_field('Content-Type', 'application/json')
            request.add_field('Authorization', @sessionToken)
            request.body =  {"UserName"=> @ProviderUsername}.to_json
            response = @httpInstance.request(request)
            
            if response.code == "201"
                @logger.info(@flowName + "() : User '" + @ProviderUsername + "' was successfully added to group '" + addToGroup + "'")
                next
            end            

            responseHash = JSON.parse(response.body)
            
            if responseHash["ErrorCode"] == "ITATS262E"
                @logger.info(@flowName + "() : User '" + @ProviderUsername + "' is already a member of Group '" + addToGroup + "'")
                next
            end    
            
            if responseHash["ErrorCode"] != nil
                @logger.warn(@flowName + "() : Received response " + responseHash["ErrorCode"] + " - " + responseHash["ErrorMessage"])
                return false
            end            
            
            @logger.error(@flowName + "() : Received unexpected response when adding user to group")
            return false

        end
        
        return true
    end    
    
    ###########################################################################################
    def logoff()
        @logger.info(@flowName + "() : Closing session")
        
        # logging off
        request = Net::HTTP::Post.new(@http_host + "/PasswordVault/WebServices/auth/SAML/SAMLAuthenticationService.svc/Logoff")
        request.add_field('Content-Type', 'application/json')
        request.add_field('Authorization', @sessionToken)
        response = @httpInstance.request(request)
        @sessionToken = ""
        return true
    end



end