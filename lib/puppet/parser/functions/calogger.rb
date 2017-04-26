# ------------------------------------------------------------------------------------------
#   Copyright (c) 2016 CyberArk Software Inc.
#
#    
#
#  Optionally initialize log file for deployed provider.
# ------------------------------------------------------------------------------------------

require 'logger'

module Puppet::Parser::Functions
    newfunction(:calogger, :type => :rvalue) do |args|   
    
        # Full path to log file. If an empty string is set (""), then logs will be redirected to Puppet builtin logging mechanism.
        fullPathLogFilename = args[0]    
        
        # The log file is flushed if max_size_log_file is reached.
        max_size_log_file = args[1]
       
        if fullPathLogFilename == ""
            logger = Logger.new(STDOUT)      
        else
            if File.file?(fullPathLogFilename)
                # To prevent a huge log file, flush file if above 'max_size_log_file'
                if File.stat(fullPathLogFilename).size > max_size_log_file
                    File.delete(fullPathLogFilename)
                end
            end
            fileHandle = File.open(fullPathLogFilename, "a")    
            logger = Logger.new(fileHandle)      
        end
        
        logger.debug("****************************************")
        logger.debug("********** Invoking  AIM  class ********")
        logger.debug("****************************************")
        logger.close
  end
end
