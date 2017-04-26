
Puppet::Type.newtype(:aim_provider) do

	ensurable do
    	defaultvalues
    	defaultto :present
  	end

	newparam(:name, :namevar => true) do
		desc 'An arbitrary name used as the identity of the resource.'
	end

	newproperty(:version, :readonly => true) do
		desc "AIM Provider version."
	end
	
	newproperty(:provider_username, :readonly => true) do
    	desc "AIM Provider username."
    end

end
