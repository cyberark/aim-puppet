
require 'securerandom'

class aim::environment {
    
    $getAdminInfo = { "appId" => $aim::provider::admin_credential_aim_appid,
                      "query" => $aim::provider::admin_credential_aim_query,
                    }
    
    if ($aim::provider::ensure == 'present') {
        
        if ($aim::provider::package_is_installed == false) {

            # Retrieve administrative credential
            $user_and_pwd = cyberark_credential($getAdminInfo, $aim::provider::aim_path_log_file)
            
            $prov_user_pwd = cyberark_random_password()
            
            # Ensure Provider User is created.
            cyberark_user { $aim::provider::provider_username:
                base_url => $aim::provider::webservices_sdk_baseurl,
                use_shared_logon_authentication => false,
                login_username => $user_and_pwd[0],
                login_password => $user_and_pwd[1],
                initial_password => $prov_user_pwd,
                groups_to_be_added_to => $aim::provider::provider_user_groups,
                user_type_name => "AppProvider",
                location => $aim::provider::provider_user_location,
            }            
            
            # Create credential file for the new provider 
            exec { 'createcred_exec' :
                command => "/opt/CARKaim/bin/createcredfile /etc/opt/CARKaim/vault/appprovideruser.cred Password -Username $aim::provider::provider_username -Password $prov_user_pwd -apptype AppPrv -hostname -displayrestrictions",
                cwd => '/opt/CARKaim/bin/',
            }  

        }

    } elsif ($aim::provider::ensure == 'absent') {

        # Retrieve administrative credential        
        $user_and_pwd = cyberark_credential($getAdminInfo, $aim::provider::aim_path_log_file)

        # Ensure Provider user is removed.
        cyberark_user { $aim::provider::provider_username:
            ensure => "absent",
            base_url => $aim::provider::webservices_sdk_baseurl,
            use_shared_logon_authentication => false,
                login_username => $user_and_pwd[0],
                login_password => $user_and_pwd[1],
        }
        
    }
}
