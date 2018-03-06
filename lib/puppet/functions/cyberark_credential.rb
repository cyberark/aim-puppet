require 'logger'
require 'open3'


Puppet::Functions.create_function(:'cyberark_credential') do

  dispatch :cyberark_credential do
    param 'Hash', :pwdAdminInfo
    param 'String', :fullLogFileName # optional
    return_type 'Array[String]'
  end

  def cyberark_credential(pwdAdminInfo, fullLogFileName)

    @pwdAdminInfo = pwdAdminInfo

    if fullLogFileName == ""
      @logger = Logger.new(STDOUT)
    else
      @logger = Logger.new(fullLogFileName)
    end

    @logger.info("Retrieve administrative credential for deployment via CLIPASSWORDSDK with the following query:")

    @clipasswordsdk_cmd = ENV['AIM_CLIPASSWORDSDK_CMD'] || '/opt/CARKaim/sdk/clipasswordsdk'

    @query = "";

    if @pwdAdminInfo.key? "query"
      @query = @pwdAdminInfo["query"]
    else
      if @pwdAdminInfo.key? "safe"
        @query = 'safe=' + @pwdAdminInfo["safe"] + ';'
      end
      if @pwdAdminInfo.key? "folder"
        @query = @query + 'folder=' + @pwdAdminInfo["folder"] + ';'
      end
      if @pwdAdminInfo.key? "object"
        @query = @query + 'object=' + @pwdAdminInfo["object"] + ';'
      end
    end

    @fullCmd = "#{@clipasswordsdk_cmd} GetPassword -p AppDescs.AppId=\"#{@pwdAdminInfo['appId']}\" -p Query=\"#{@query}\" -o PassProps.UserName,Password"

    result = Array.new

    begin
      @logger.info("To execute = " + @fullCmd)
      Open3.popen3(@fullCmd) do |stdin, stdout, stderr, wait_thr|
        @logger.info("****")
        exit_status = wait_thr.value
        unless exit_status.success?
          error_msg = "#{@fullCmd}\n"
          stderr.each_line do |line|
            error_msg = "#{error_msg}\n#{line}"
          end
          abort error_msg
        end
        line = stdout.gets
        result = line.gsub("\n","").split(",")
      end

      @logger.debug(" Result = " + result[0]);

      return result
    rescue Exception => e
      @logger.error("GetPass() : Got Exception on call to GetPassword :" + e.message )
      raise e
    end
  end
end


