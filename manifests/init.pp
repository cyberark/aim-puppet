# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# aim::provider
#
# Main class, includes all other classes.
#

# @param ensure [String] Either "present" or "absent".
# @param vault_address [String] Specifies the CyberArk Vault address either hostname or IP.
# @param vault_port [Integet] Specifies the communication port to CyberArk Vault, by default it uses port 1858.
# @param admin_credential_aim_appid [String] Specifies the CyberArk Application ID to be used during the AIM query for admin credential.
# @param admin_credential_aim_query [String] Specifies the AIM query to obtain the admin credentials to perform actions in CyberArk.
# @param use_shared_logon_authentication [Boolean] Specifies whether to use shared logon auth for CyberArk WebServices REST API calls.
# @param aim_path_log_file [Stdlib::Absolutepath] Specifies the path for the AIM operations log file.
# @param provider_user_location [String] Specifies CyberArk location for the provider user to be place at creation.
# @param provider_safe_config [String] Specifies the name of the provider configuration safe.
# @param provider_username [String] Specifies the name of the provider user.
# @param provider_user_groups [String] Specifies the group(s) to add the provider user right after creation.
# @param webservices_certificate_file [Optional String] Specifies full path for certificate to use for CyberArk WebServices REST API Calls.
# @param webservices_sdk_baseurl [Stdlib::Httpurl] Specifies the Base URL for CyberArk WebServices Rest API Calls.
# @param main_app_provider_conf_file [String] Specifies the name of the provider's main configuration file.
# @param aim_distribution_file [String] Specifies the name of the AIM Zip distribution file.
# @param aim_folder_within_distribution [String] Specifies the folder within distribution file containing installation files for provider.
# @param distribution_source_path [String] Specifies the distribution file (like "puppet:///aim_module").
# @param aim_rpm_to_install [String] Specifies the name of the RPM file to install.

class aim::provider (
    String $ensure = 'present',
    String $vault_address = $aim::params::vault_address,
    Integer $vault_port = $aim::params::vault_port,
    String $admin_credential_aim_appid = $aim::params::admin_credential_aim_appid,
    String $admin_credential_aim_query = $aim::params::admin_credential_aim_query,
    Boolean $use_shared_logon_authentication = $aim::params::use_shared_logon_authentication,
    Stdlib::Absolutepath $aim_path_log_file = $aim::params::aim_path_log_file,
    String $provider_user_location = $aim::params::provider_user_location,
    String $provider_safe_config = $aim::params::provider_safe_config,
    String $provider_username = $aim::params::provider_username,
    String $provider_user_groups = $aim::params::provider_user_groups,
    Optional[String] $webservices_certificate_file = $aim::params::webservices_certificate_file,
    Stdlib::Httpurl $webservices_sdk_baseurl = $aim::params::webservices_sdk_baseurl,
    String $main_app_provider_conf_file = $aim::params::main_app_provider_conf_file,
    String $aim_distribution_file = $aim::params::aim_distribution_file,
    String $aim_folder_within_distribution = $aim::params::aim_folder_within_distribution,
    String $distribution_source_path = $aim::params::distribution_source_path,
    String $aim_rpm_to_install = $aim::params::aim_rpm_to_install,
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
