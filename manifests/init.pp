# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to 
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------


class aim::provider( 
    $ensure                         = 'present',
    $vault_address                  = $aim::params::vault_address,
    $vault_port                     = $aim::params::vault_port,
    $admin_credential_aim_appid     = $aim::params::admin_credential_aim_appid,
    $admin_credential_aim_query     = $aim::params::admin_credential_aim_query,
    $aim_path_log_file              = $aim::params::aim_path_log_file,
    $provider_user_location         = $aim::params::provider_user_location,
    $provider_safe_config           = $aim::params::provider_safe_config,
    $provider_username              = $aim::params::provider_username,
    $provider_user_groups           = $aim::params::provider_user_groups,
    $certificate_file               = $aim::params::certificate_file,
    $webservices_sdk_baseurl        = $aim::params::webservices_sdk_baseurl,
    $main_app_provider_conf_file    = $aim::params::main_app_provider_conf_file,
    $aim_distribution_file          = $aim::params::aim_distribution_file,
    $aim_folder_within_distribution = $aim::params::aim_folder_within_distribution,
    $distribution_source_path       = $aim::params::distribution_source_path,
    $aim_rpm_to_install             = $aim::params::aim_rpm_to_install,
) inherits  aim::params {
    
    
    include '::aim::package'
    include '::aim::environment'
    include '::aim::service'

    anchor { 'aim::provider::start': }
    -> Class['aim::package']
    ~> Class['aim::environment']
    -> Class['aim::service']
    -> anchor { 'aim::provider::end': }
          
}
