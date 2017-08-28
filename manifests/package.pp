
# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Manifest of AIM module. It defines for puppet the steps that should be taken in order to
# (un)install the Credential Provider on the node.
# ------------------------------------------------------------------------------------------

# aim::package
#
# The aim::package class makes sure the AIM provider package (along with configuration files) is installed
# when ensure == "present", it will unzip distribution, setup parameters in configuration files, setup
# permissions on files, and installs the distribution package.
# In case of ensure == "absent", it will uninstall the CARKaim package and remove distribution folders.
#

class aim::package {

    if ($aim::provider::ensure == 'present') {

        # notify {"CyberArk aim::package [${aim::provider::package_is_installed}]": withpath => true}

        if ($aim::provider::package_is_installed == false) {


            if ($aim::provider::aim_folder_within_distribution == '') {
                $folder_within_archive = $aim::provider::aim_distribution_file.split('-')[0]
            } else {
                $folder_within_archive = $aim::provider::aim_folder_within_distribution
            }

            $tmp_directory = $aim::provider::aim_distribution_file
            $aim_file_archive = $aim::provider::aim_distribution_file

            $full_path = "${tmp_directory}/${aim_file_archive}"

            # conditional logic with exec where if the folder exists then go to remove, and then straight to creation

            exec { 'remove_temp_folder_ifexists':
                path    => '/bin',
                command => "rm -fr ${tmp_directory} ",
                onlyif  => "test -d ${tmp_directory}"
            }

            # make dir temporary folder
            file {'create_directory':
                ensure  => 'directory',
                path    => $tmp_directory,
                require => Exec['remove_temp_folder_ifexists']
            }

            file { 'deliver_file':
                path    => $full_path,
                mode    => '0700',
                owner   => root,
                group   => root,
                source  => "${aim::provider::distribution_source_path}/${aim_file_archive}",
                require => File['create_directory'],
            }

            archive { 'extract_install_files':
                path         => $full_path,
                extract      => true,
                extract_path => $tmp_directory,
                creates      => "${tmp_directory}/${folder_within_archive}",
                require      => File['deliver_file'],
            }

            # chmod CreateCredFile to executable
            file { 'change_createcredfile':
                path    => "${tmp_directory}/CreateCredFile",
                mode    => '0700',
                require => Archive['extract_install_files'],
            }

            file { 'copy_aimparms':
                ensure  => present,
                path    => '/var/tmp/aimparms',
                source  => "${tmp_directory}/${folder_within_archive}/aimparms.sample",
                require => File['change_createcredfile'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'AcceptCyberArkEULA':
                ensure  => present,
                section => 'Main',
                setting => 'AcceptCyberArkEULA',
                value   => 'Yes',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'LicensedProducts':
                ensure  => present,
                section => 'Main',
                setting => 'LicensedProducts',
                value   => 'AIM',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'CreateVaultEnvironment':
                ensure  => present,
                section => 'Main',
                setting => 'CreateVaultEnvironment',
                value   => 'No',
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'VaultFilePath':
                ensure  => present,
                section => 'Main',
                setting => 'VaultFilePath',
                value   => "${tmp_directory}/${folder_within_archive}/Vault.ini",
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Changes to /var/tmp/aimparms
            ini_setting { 'MainAppProviderConfFile':
                ensure  => present,
                section => 'Main',
                setting => 'MainAppProviderConfFile',
                value   => $aim::provider::main_app_provider_conf_file,
                path    => '/var/tmp/aimparms',
                require => File['copy_aimparms'],
            }

            # Install Package
            package { 'CARKaim':
                ensure   => installed,
                source   => "${tmp_directory}/${folder_within_archive}/${aim::provider::aim_rpm_to_install}",
                provider => 'rpm',
                require  => Ini_setting['VaultFilePath'],
            }

            # Copy file vault.ini to /etc/opt/CARKaim/vault
            file { 'CopyVaultConfigFileParams':
                ensure  => present,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                source  => "${tmp_directory}/${folder_within_archive}/Vault.ini",
                require => Package['CARKaim'],
            }


            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultAddress':
                ensure  => present,
                section => '',
                setting => 'ADDRESS',
                value   => $aim::provider::vault_address,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                require => File['CopyVaultConfigFileParams'],
            }

            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultPort':
                ensure  => present,
                section => '',
                setting => 'PORT',
                value   => $aim::provider::vault_port,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                require => File['CopyVaultConfigFileParams'],
            }

            if ($aim::provider::main_app_provider_conf_file != '') {
                # Changes to /etc/opt/CARKaim/conf/basic_appprovider.conf
                ini_setting { 'modifyBasicAppPrvConfig':
                    ensure  => present,
                    section => 'Main',
                    setting => 'AppProviderVaultParmsFile',
                    value   => $aim::provider::main_app_provider_conf_file,
                    path    => '/etc/opt/CARKaim/conf/basic_appprovider.conf',
                    require => File['CopyVaultConfigFileParams'],
                }
            }

            # delete unconditionally (no 'require') temporary folder
            exec {'remove_unconditionally_tmp_directory':
                command => "/bin/rm -rf ${tmp_directory}",
                cwd     =>'/tmp/',
                require => File['CopyVaultConfigFileParams'],
            }

        } else {
            # packaged is already installed
            notify {'CyberArk AIM Package is already installed': withpath => true}
        }

    } elsif ($aim::provider::ensure == 'absent') {

        if ($aim::provider::package_is_installed) {
            # Uninstall Package
            package { 'CARKaim':
                ensure   => 'absent',
                provider => 'rpm',
            }

            # delete unconditionally (no 'require') /etc/opt/CARKaim
            exec {'/bin/rm -rf /etc/opt/CARKaim  ':
                cwd     =>'/tmp/',
                require => Package['CARKaim'],
            }

            # delete unconditionally (no 'require') /var/opt/CARKaim
            exec {'/bin/rm -rf /var/opt/CARKaim  ':
                cwd     =>'/tmp/',
                require => Package['CARKaim'],
            }
        }

    }

}
