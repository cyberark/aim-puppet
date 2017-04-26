

class aim::params {
    
    $package_is_installed = ($installed_carkaim =~ /CARKaim-.*/)
    
    $vault_address                  = ""
    $vault_port                     = "1858"
    
    # The name of the deployed AIM provider is by default defined by the prefix 'Prov_' along with $hostname
    $cp_user_prefix                 = 'Prov_'
    $cp_user                        = "${cp_user_prefix}$hostname" 
    
    # a set of key-value pairs that required for retrieval of admin credential.
    # note that the key "query" comes as alternative to "safe", "folder" and "object"
    $admin_credential_aim_appid     = 'PuppetTest'
    $admin_credential_aim_query     = 'Safe=CyberArk Passwords;Folder=ROOT;Object=AdminPass'
    
    $aim_path_log_file              = "/tmp/deploy${$hostname}.log"
    
    $provider_user_location         = '\\Applications'
    $provider_safe_config           = 'AppProviderConf'
    $provider_username              = $cp_user
    $provider_user_groups           = ""
    $certificate_file               = '/opt/puppetlabs/puppet/ssl/cert.pem'
    
    $webservices_sdk_baseurl        = 'https://Win2012R2-Template'
    

    # As prerequisite, configuration file should already exist in the vault and its name is given by cp_config_file                             
    $cp_config_file                 = 'main_agent_appprovider.conf'
    
    # The filename of the RPM  to be installed
    $installed_rpm                  = 'CARKaim-9.60.0.17.x86_64.rpm'
    
}