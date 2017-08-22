
require 'securerandom'

# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# aim::environment
#
# The aim::environment class makes sure the environment for the provider user is setup (if ensure == "present")
# by creating the user in CyberArk Vault with a random password and creating a credential file for it.
# It also makes sure the provider user is removed when ensure == "absent".
#

class aim::environment {

    $get_admin_info = { 'appId' => $aim::provider::admin_credential_aim_appid,
                        'query' => $aim::provider::admin_credential_aim_query,
                      }

    if ($aim::provider::ensure == 'present') {

        if ($aim::provider::package_is_installed == false) {

            if $aim::provider::use_shared_logon_authentication == false {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $aim::provider::aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            $prov_user_pwd = cyberark_random_password()

            # Ensure Provider User is created.
            cyberark_user { $aim::provider::provider_username:
                base_url                        => $aim::provider::webservices_sdk_baseurl,
                #webservices_certificate_file => $aim::provider::certificate_file,
                use_shared_logon_authentication => $aim::provider::use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
                initial_password                => $prov_user_pwd,
                groups_to_be_added_to           => $aim::provider::provider_user_groups,
                user_type_name                  => 'AppProvider',
                location                        => $aim::provider::provider_user_location,
            }

            # Create credential file for the new provider
            exec { 'createcred_exec' :
                command => "/opt/CARKaim/bin/createcredfile /etc/opt/CARKaim/vault/appprovideruser.cred Password \
                            -Username ${aim::provider::provider_username} -Password ${prov_user_pwd} \
                            -apptype AppPrv -hostname -displayrestrictions",
                cwd     => '/opt/CARKaim/bin/',
            }

        }

    } elsif ($aim::provider::ensure == 'absent') {

        if ($aim::provider::package_is_installed) {

            if $aim::provider::use_shared_logon_authentication == false {
                # Retrieve administrative credential
                $user_and_pwd = cyberark_credential($get_admin_info, $aim::provider::aim_path_log_file)
                $session_id = cyberark_new_session_id()
            } else {
                $user_and_pwd = ['','']
                $session_id = 0
            }

            # Ensure Provider user is removed.
            cyberark_user { $aim::provider::provider_username:
                ensure                          => 'absent',
                base_url                        => $aim::provider::webservices_sdk_baseurl,
                #webservices_certificate_file => $aim::provider::webservices_certificate_file,
                use_shared_logon_authentication => $aim::provider::use_shared_logon_authentication,
                connection_number               => $session_id,
                login_username                  => $user_and_pwd[0],
                login_password                  => $user_and_pwd[1],
            }
        }
    }
}
