

class aim::service {
    
    if ($aim::provider::ensure == 'present') {
    
        service { "aimprv":
            ensure => running,
            provider => 'redhat',
        }
                
    }
}