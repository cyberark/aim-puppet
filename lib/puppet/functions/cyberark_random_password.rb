# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_credential - it retrieves a credential from CyberArk Vault. It uses CyberArk
#                           Java Password SDK, passing the criteria based on parameters.
#
# ------------------------------------------------------------------------------------------

require 'securerandom'

Puppet::Functions.create_function(:'cyberark_random_password') do 

  dispatch :cyberark_random_password do
    return_type 'String'
  end

  def cyberark_random_password()
    return "X_"+SecureRandom.hex(10)
  end

end

