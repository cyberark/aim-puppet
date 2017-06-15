# Forward declaration(s)
module CyberArk; end
module CyberArk::WebServices; end

module CyberArk::WebServices::Type
    
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def add_parameter_base_url
      newparam(:base_url) do
        desc 'The base URL for CyberArk WebServices SDK API.'
        munge do |value|
          String(value)
        end
      end
    end
    
    def add_parameter_webservices_certificate_file
      newparam(:webservices_certificate_file) do
        desc 'Certificate File to be used when invoking HTTPS webservice calls.'
        munge do |value|
          String(value)
        end
      end
    end

    def add_parameter_login_username
      newparam(:login_username) do
        desc 'The login username to be used to authenticate with CyberArk WebServices SDK API.'
        munge do |value|
          String(value)
        end
      end
    end

    def add_parameter_login_password
      newparam(:login_password) do
        desc 'The password to be used to authenticate with CyberArk WebServices SDK API.'
        munge do |value|
          String(value)
        end
      end
    end
    
    def add_parameter_login_newpassword
      newparam(:login_newpassword) do
        desc 'The new password of the login user. This parameter is optional, and enables you to change a password.'
        munge do |value|
          String(value)
        end
      end
    end
    
    def add_parameter_use_radius_authentication
      newparam(:use_radius_authentication) do
        desc 'Whether or not users will be authenticated via a RADIUS server. Valid values: true/false.'
        defaultto :false
        newvalues(:true, :false)
        munge do |value|
          String(value)
        end
      end
    end
    
    def add_parameter_connection_number
      newparam(:connection_number) do
        desc 'In order to allow more than one connection for the same user simultaneously, each request should be sent with different "connectionNumber". Valid values: 0-100.'
        munge do |value|
          String(value)
        end
      end
    end
    
    def add_parameter_use_shared_logon_authentication
      newparam(:use_shared_logon_authentication) do
        desc 'Whether or not users will be authenticated via a RADIUS server. Valid values: true/false.'
        defaultto :false
        newvalues(:true, :false)
        munge do |value|
          String(value)
        end
      end
    end    
    
  end
end
