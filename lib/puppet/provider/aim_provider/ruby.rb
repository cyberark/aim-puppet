require 'puppet/util/inifile'

Puppet::Type.type(:aim_provider).provide(:ruby) do

	commands :package => 'rpm',
	         :echo => 'echo'

    mk_resource_methods
    
    def self.prefetch(resources)
        instances.each do |prov|
            if resource = resources[prov.name]
              resource.provider = prov
            end
        end
    end    

	def self.instances
		Puppet.debug("Getting instances")
		echo(["Getting Instances", ">>", "/var/tmp/test.out"])
		output = get_provider_package_information()
		result = []
		Puppet.debug(output)
		if output and output =~ /^#{Regexp.escape('CARKaim')}-(.*)/
    		Puppet.debug($1)
    		_version = $1
    		_provider_username = ""
            # test
            inifile = File.read("/etc/opt/CARKaim/vault/appprovideruser.cred")
            inifile.each_line do |line|
                if line =~ /[Uu]sername=(.*)/
                    Puppet.debug($1)
                    _provider_username = $1
                end
            end
    		result[0] = new(:name => 'CARKaim',
    		    :ensure => :present,
    		    :version => _version,
    		    :provider_username => _provider_username)
		else
			result[0] = new(:name => 'CARKaim',
			                :ensure => :absent)
		end
		result
	end
	
    def exists?
        @property_hash[:ensure] == :present
    end

	def destroy
		package(['-e', 'CARKaim'])
	end

	def create
		package(['-i', 'CARKaim'])
	end
	
	def version
    	@property_hash[:version]
    end

	def provider_username
    	@property_hash[:provider_username]
    end

	def self.get_provider_package_information()
		begin
			output = package(['-q', 'CARKaim'])
		rescue Puppet::ExecutionFailure => e
			Puppet.debug("#Error in get_provider_package_information -> #{e.inspect}")
			return nil
		end
		return nil if output !~ /CARKaim-.*/
		output
	end

end
