# ------------------------------------------------------------------------------------------
#   Copyright (c) 2017 CyberArk Software Inc.
#
# Functions:
#
#  * :cyberark_credential - it retrieves a credential from CyberArk Vault. It uses CyberArk
#                           Java Password SDK, passing the criteria based on parameters.
#
# ------------------------------------------------------------------------------------------

Puppet::Functions.create_function(:'cyberark_new_session_id') do 

  dispatch :cyberark_new_session_id do
    return_type 'Integer'
  end

  def cyberark_new_session_id()

    filenameCounterSessionId = "/tmp/counter_aim_sessionid"

    sid = 0

    # Use file lock mechanism to achieve atomic sessionId allocation. Effective range is 1-100
    # (Some OSs might not support flock)
    File.open(filenameCounterSessionId, File::RDWR|File::CREAT, 0644) {|f|
      f.flock(File::LOCK_EX)
      sid = f.read.to_i + 1
      if sid == 100
        sid = 1
      end
      f.rewind
      f.write("#{sid}\n")
      f.flush
      f.truncate(f.pos)
    }
    return sid
  end

end

