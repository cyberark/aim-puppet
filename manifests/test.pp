
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

class aim::test {

    if ($aim::provider::package_is_installed == true) {
      $get_admin_info = { 'appId' => 'PuppetTest',
                          'query' => 'Safe=CyberArk Passwords;Folder=Root;Object=AdminPass',
                        }

      $user_and_pwd = cyberark_credential($get_admin_info, '/tmp/deployTest.log')

      notify { "***** User=${user_and_pwd[0]} and Password=${user_and_pwd[1]}": }
    } else {
      notify { "AIM Package is not installed!": }
    }

}
