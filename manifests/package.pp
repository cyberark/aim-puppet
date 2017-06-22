

class aim::package {

    if ($aim::provider::ensure == 'present') {

        notify {"CyberArk aim::package [${aim::provider::package_is_installed}]": withpath => true}

        if ($aim::provider::package_is_installed == false) {


            if ($aim::provider::aim_folder_within_distribution == '') {
                $folder_within_archive = $aim::provider::aim_distribution_file.split('-')[0]
            } else {
                $folder_within_archive = $aim::provider::aim_folder_within_distribution
            }

            $tmp_directory = '/tmp/puppetInstallAIM'
            $aim_file_archive = $aim::provider::aim_distribution_file

            $full_path = "${tmp_directory}/${aim_file_archive}"

            # make dir temporary folder 'puppetInstallAIM'
            file {'create_directory':
                ensure => 'directory',
                path   => $tmp_directory,
            }

            # remove unconditionally temporary folder
            tidy {'remove_directory_content':
                path    => $tmp_directory,
                recurse => true,
                rmdirs  => true,
                require => File['create_directory'],
            }

            file { 'deliver_file':
                path    => $full_path,
                mode    => '0700',
                owner   => root,
                group   => root,
                source  => "${aim::provider::distribution_source_path}/${aim_file_archive}",
                require => Tidy['remove_directory_content'],
            }

            archive { 'extract_install_files':
                path         => $full_path,
                extract      => true,
                extract_path => $tmp_directory,
                creates      => "${tmp_directory}/${folder_within_archive}",
                require      => File['deliver_file'],
            }

            # copy installation folder to avoid recursive dependency
            file { 'duplicate installation folder':
                path    => '/tmp/installation',
                source  => "${tmp_directory}/${folder_within_archive}",
                recurse => true,
                require => Archive['extract_install_files'],
            }

            # chmod CreateCredFile to executable
            file { 'change_createcredfile':
                path    => '/tmp/installation/CreateCredFile',
                mode    => '0700',
                require => File['duplicate installation folder'],
            }

            file { 'copy_aimparms':
                ensure  => present,
                path    => '/var/tmp/aimparms',
                source  => '/tmp/installation/aimparms.sample',
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
                value   => '/tmp/installation/Vault.ini',
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
                source   => "/tmp/installation/${aim::provider::aim_rpm_to_install}",
                provider => 'rpm',
                require  => Ini_setting['VaultFilePath'],
            }

            # Copy file vault.ini to /etc/opt/CARKaim/vault
            file { 'CopyVaultConfigFileParams':
                ensure  => present,
                path    => '/etc/opt/CARKaim/vault/vault.ini',
                source  => '/tmp/installation/Vault.ini',
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

            # delete unconditionally (no 'require') temporary folder 'puppetInstallAIM'
            exec {'/bin/rm -rf /tmp/puppetInstallAIM  ':
                cwd     =>'/tmp/',
                require => File['CopyVaultConfigFileParams'],
            }

            # delete unconditionally (no 'require') temporary folder 'puppetInstallAIM'
            exec {'/bin/rm -rf /tmp/installation  ':
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
