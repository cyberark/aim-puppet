

class aim::package {
    
    if ($aim::provider::ensure == 'present') {
    
        if ($aim::provider::package_is_installed == false) {
            
            $tmpDirectory = '/tmp/puppetInstallAIM'
            $aimFileArchive = 'RHELinux-x64-Rls-v9.8.zip'
            $folderWithinArchive = "RHELinux x64"
            
            $fullPath = "${tmpDirectory}/${aimFileArchive}"
            
            # notify {"Package is not installed!":}
            
            # make dir temporary folder 'puppetInstallAIM'   
            file {'create_directory':
                path => $tmpDirectory,
                ensure => 'directory',
            } 
            
            # remove unconditionally temporary folder
            tidy {'remove_directory_content':
                path => $tmpDirectory,
                recurse => true,
                rmdirs => true,
                require => File['create_directory'],
             }
                             
            file { "deliver_file":
                path => $fullPath,
                mode => '700',
                owner => root,
                group => root,
                source => "puppet:///aim_module/${aimFileArchive}",  
                require => Tidy['remove_directory_content'],
            }
            
            archive { 'extract_install_files':
                path => $fullPath,
                extract => true,
                extract_path => $tmpDirectory,
                creates      => "${tmpDirectory}/${folderWithinArchive}",
                require => File["deliver_file"],
            }
            
            # copy installation folder to avoid recursive dependency
            file { 'duplicate installation folder':
                path => "/tmp/installation",
                source => "${tmpDirectory}/${folderWithinArchive}",
                recurse => true,
                require => Archive["extract_install_files"],
            }
    
            # chmod CreateCredFile to executable 
            file { 'change_createcredfile':
                path => "/tmp/installation/CreateCredFile",
                mode => '700',
                require => File['duplicate installation folder'],
            }
            
            file { 'copy_aimparms':
                path => "/var/tmp/aimparms",
                ensure => present,
                source => "/tmp/installation/aimparms.sample",
                require => File["change_createcredfile"],    
            }
            
            # Changes to /var/tmp/aimparms
            ini_setting { 'AcceptCyberArkEULA':
                ensure => present,
                section => 'Main',
                setting => 'AcceptCyberArkEULA',
                value => 'Yes',
                path => "/var/tmp/aimparms",
                require => File["copy_aimparms"],
            }
    
            # Changes to /var/tmp/aimparms
            ini_setting { 'LicensedProducts':
                ensure => present,
                section => 'Main',
                setting => 'LicensedProducts',
                value => 'AIM',
                path => "/var/tmp/aimparms",
                require => File["copy_aimparms"],
            }
            
            # Changes to /var/tmp/aimparms
            ini_setting { 'CreateVaultEnvironment':
                ensure => present,
                section => 'Main',
                setting => 'CreateVaultEnvironment',
                value => 'No',
                path => "/var/tmp/aimparms",
                require => File["copy_aimparms"],
            }
    
            # Changes to /var/tmp/aimparms
            ini_setting { 'VaultFilePath':
                ensure => present,
                section => 'Main',
                setting => 'VaultFilePath',
                value => '/tmp/installation/Vault.ini',
                path => "/var/tmp/aimparms",
                require => File["copy_aimparms"],
            }
            
            # Install Package 
            package { "CARKaim":
                ensure  => installed,
                source  => "/tmp/installation/CARKaim-9.80.0.85.x86_64.rpm",
                provider => 'rpm',
                require => Ini_setting["VaultFilePath"],
            }
            
            # Copy file vault.ini to /etc/opt/CARKaim/vault
            file { 'CopyVaultConfigFileParams':
                path => "/etc/opt/CARKaim/vault/vault.ini",
                ensure => present,
                source => "/tmp/installation/Vault.ini",
                require => Package["CARKaim"],    
            }            


            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultAddress':
                ensure => present,
                section => '',
                setting => 'ADDRESS',
                value => "$aim::provider::vault_address",
                path => "/etc/opt/CARKaim/vault/vault.ini",
                require => File["CopyVaultConfigFileParams"],
            }

            # Changes to /etc/opt/CARKaim/vault/vault.ini
            ini_setting { 'UpdateVaultPort':
                ensure => present,
                section => '',
                setting => 'PORT',
                value => "$aim::provider::vault_port",
                path => "/etc/opt/CARKaim/vault/vault.ini",
                require => File["CopyVaultConfigFileParams"],
            }

            
            # delete unconditionally (no 'require') temporary folder 'puppetInstallAIM'
            exec {'/bin/rm -rf /tmp/puppetInstallAIM  ':
                cwd =>'/tmp/',
                require => File["CopyVaultConfigFileParams"],
            }  
            
            # delete unconditionally (no 'require') temporary folder 'puppetInstallAIM'
            exec {'/bin/rm -rf /tmp/installation  ':
                cwd =>'/tmp/',
                require => File["CopyVaultConfigFileParams"],
            }  
                        
        } else {
            # packaged is already installed
            notice("CyberArk AIM Package is already installed")
        }
        
    } elsif ($aim::provider::ensure == 'absent') {
        
        # Install Package 
        package { "CARKaim":
            ensure  => 'absent',
            source  => "/tmp/installation/CARKaim-9.80.0.85.x86_64.rpm",
            provider => 'rpm',
        }
        
    }
   
}