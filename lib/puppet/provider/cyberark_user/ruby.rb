
require_relative '../../../puppet_x/cyberark/webservices.rb'

Puppet::Type.type(:cyberark_user).provide(:ruby, :parent => PuppetX::CyberArk::WebServices) do

    mk_resource_methods

    def initialize(value={})
        super(value)
        @property_flush = {}
    end

    def self.instances
        Puppet.debug("def self.instances ==> returning empty list")
        return []
    end

    def self.prefetch(resources)

        Puppet.debug("Pre-fetch")
        instances.each do |prov|
            if resource = resources[prov.name]
              resource.provider = prov
            end
        end

    end

    def underscore(value)

        value.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase

    end

    def exists?

        Puppet.debug("def exists?")
        # Puppet.debug("*** LOGIN username => #{@resource[:login_username]}")
        result = PuppetX::CyberArk::WebServices.get("/PasswordVault/WebServices/PIMServices.svc/Users/#{self.name}", data: nil, resource: @resource)
        Puppet.debug("Result => #{result}")

        if result && result.key?("UserName")
            return true
        else
            return false
        end

    end

    def flush

        Puppet.debug("FLUSH")

        Puppet.debug(" property_flush => #{@property_flush.to_json}")

        data = {}

        @property_flush.each do |key, value|
            newKey = (key.to_s.split("_").each {|s| s.capitalize! }.join(""))
            data[newKey] = value
        end

        # Puppet.debug(" data => #{data.to_json}")

        if !data.empty?
            result = PuppetX::CyberArk::WebServices.put("/PasswordVault/WebServices/PIMServices.svc/Users/#{@resource[:username]}", data: data.to_json)

            @property_hash = resource.to_hash
        end

    end

    # ==== Updateable properties ===========

    def user_type_name=(value)
        @property_flush[:user_type_name] = value
    end

    def email=(value)
        @property_flush[:email] = value
    end

    def first_name=(value)
        @property_flush[:first_name] = value
    end

    def last_name=(value)
        @property_flush[:last_name] = value
    end

    def change_password_on_the_next_logon=(value)
        @property_flush[:change_password_on_the_next_logon] = value
    end

    def expiry_date=(value)
        @property_flush[:expiry_date] = value
    end

    def disabled=(value)
        @property_flush[:disabled] = value
    end

    def location=(value)
        @property_flush[:location] = value
    end

    # ======================================

	def destroy
    	Puppet.debug("DESTROY")
    	Puppet.debug(@resource[:username])
    	result = PuppetX::CyberArk::WebServices.delete("/PasswordVault/WebServices/PIMServices.svc/Users/#{@resource[:username]}")
	end

	def create
    	Puppet.debug("CREATE")

    	Puppet.debug(@resource)

    	data = {}

    	if @resource[:username]
        	data[:UserName] = @resource[:username]
      end

    	if @resource['initial_password']
        	data[:InitialPassword] = @resource['initial_password']
      end

    	if @resource['email']
        	data[:Email] = @resource['email']
      end

    	if @resource['first_name']
        	data[:FirstName] = @resource['first_name']
      end

    	if @resource['last_name']
        	data[:LastName] = @resource['last_name']
      end

    	if @resource['change_password_on_the_next_logon']
        	data[:ChangePasswordOnTheNextLogon] = @resource['change_password_on_the_next_logon']
      end

    	if @resource['expiry_date']
        	data[:ExpiryDate] = @resource['expiry_date']
      end

    	if @resource['user_type_name']
        	data[:UserTypeName] = @resource['user_type_name']
      end

    	if @resource['disabled']
        	data[:Disabled] = @resource['disabled']
      end

    	if @resource['location']
        	data[:Location] = @resource['location']
      end

    	# Puppet.debug(data.to_json)
    	result = PuppetX::CyberArk::WebServices.post("/PasswordVault/WebServices/PIMServices.svc/Users", data: data.to_json, resource: nil)

    	if @resource['groups_to_be_added_to']
        	groups_array = @resource['groups_to_be_added_to'].split(",")

        	groups_array.each do | groupname |
            	Puppet.debug("Adding #{@resource[:username]} to group => #{groupname}")
            	gData = {"UserName" => @resource[:username]}
                gResult = PuppetX::CyberArk::WebServices.post("/PasswordVault/WebServices/PIMServices.svc/Groups/#{groupname}/Users", data: gData.to_json, resource: nil)
          end
      end

	end

end
