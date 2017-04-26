

class aim::environment {
    
    $getAdminInfo = { "appId" => $aim::provider::admin_credential_aim_appid,
                      "query" => $aim::provider::admin_credential_aim_query,
                    }
                    
        # information relevant to Creation/destruction of the provider in the Vault
    $createEnvInfo  =   {  # The Location in the Vault hierarchy where the Provider user will be created.
                            "location"                => $aim::provider::provider_user_location,

                            # configuration filename to be used for the deployed provider.
                            "cp_safe_config"          => $aim::provider::provider_safe_config,
                            "http_pvwa"               => $aim::provider::webservices_sdk_baseurl,
                            "cp_user"                 => $aim::provider::provider_username,
                            
                            # a chain of zero or more groups, delimited with ":"  to add the new user. Example: "myGroup1:myGroup2"
                            "add_prov_user_to_groups" => $aim::provider::provider_user_groups,
                            
                            # You can configure explicitly which certificates file of type 'pem'  to lookup for trusted 
                            # CA certificates (in order to communicate securely with PVWA). Otherwise, default 
                            # repository of certificates is being used
                            "cacert_file"             => $aim::provider::certificate_file,
                        }

    
    if ($aim::provider::ensure == 'present') {
        
        if ($aim::provider::package_is_installed == false) {

            # Retrieve administrative credential
            $user_and_pwd = passfunc($getAdminInfo, $aim::provider::aim_path_log_file)
            $prov_pwd = createenvironment($createEnvInfo, $user_and_pwd, $aim::provider::aim_path_log_file)
            
            # Create credential file for the new provider 
            exec { 'createcred_exec' :
                command => "/opt/CARKaim/bin/createcredfile /etc/opt/CARKaim/vault/appprovideruser.cred Password -Username $cp_user -Password $prov_pwd -apptype AppPrv -hostname -displayrestrictions",
                cwd => '/opt/CARKaim/bin/',
            }  

        }

    } elsif ($aim::provider::ensure == 'absent') {
        # Retrieve administrative credential
        
        $user_and_pwd = passfunc($getAdminInfo, $aim::provider::aim_path_log_file)
        deleteenvironment($createEnvInfo, $user_and_pwd, $aim::provider::aim_path_log_file)        
        
    }
}