
require 'puppet_x/webservices/type'

Puppet::Type.newtype(:cyberark_user) do
    include CyberArk::WebServices::Type

    ensurable do
        defaultvalues
        defaultto :present
    end

    newparam(:username, :namevar => true) do
        desc 'An arbitrary name used as the identity of the resource.'
    end

    add_parameter_base_url
    add_parameter_webservices_certificate_file
    add_parameter_login_username
    add_parameter_login_password
    add_parameter_login_newpassword
    add_parameter_use_radius_authentication
    add_parameter_connection_number
    add_parameter_use_shared_logon_authentication

    newparam(:initial_password)
    newparam(:groups_to_be_added_to)

    newproperty(:email)
    newproperty(:first_name)
    newproperty(:last_name)
    newproperty(:change_password_on_the_next_logon)
    newproperty(:expiry_date)
    newproperty(:user_type_name)
    newproperty(:disabled)
    newproperty(:location)

end
