# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
#   
#
#    Custom fact to provide information on installed AIM provider to Puppet
# ------------------------------------------------------------------------------------------


Facter.add('installed_carkaim') do
  setcode do
    Facter::Core::Execution.exec('/bin/rpm -q CARKaim')
  end
end

