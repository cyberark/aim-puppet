

require 'net/http'
require 'json'

module PuppetX
    
    module CyberArk
      
      class WebServices < Puppet::Provider
              
        @@session_token = ""
        
        @@authentication_info = {"username" => "scott"}
        
        @@base_url = ""
        
        @@certificate_file = ""
        
        def self.set_base_url(url)
            Puppet.debug("Setting base_url to #{url}")
            @@base_url = url
        end
        
        def self.base_url
            
            #Puppet.debug("CyberArk_PVWA_BaseURL = " +  ENV["CyberArk_PVWA_BaseURL"])
            Puppet.debug("base url = #{@@base_url}")
            
            return ENV["CyberArk_PVWA_BaseURL"] if @@base_url.empty? && ENV["CyberArk_PVWA_BaseURL"]
            return @@base_url
            
        end

        def self.set_certificate_file(certfile)
            Puppet.debug("Setting certificate file to #{certfile}")
            @@certificate_file = certfile
        end
        
        def self.certificate_file
            
            Puppet.debug("certificate file = #{@@certificate_file}")
            
            return ENV["CyberArk_PVWA_CertificateFile"] if @@certificate_file.empty? && ENV["CyberArk_PVWA_CertificateFile"]
            return @@certificate_file
            
        end

        
        def self.calling_method
            # Get calling method and clean it up for good reporting
            cm = String.new
            cm = caller[0].split(" ").last
            cm.tr!('\'', '')
            cm.tr!('\`','')
            cm
        end
        
        def rest_call(action, url, data, resource)
            self.class.rest_call(action, url, data, resource)
        end
        
        def self.post(url, data: data=nil, resource: resource=nil)
            begin
                Puppet.debug("data #{data.to_s}")
                self.rest_call('POST', url, data, resource)
            rescue Exception => e
                fail("puppet_x::CyberArk::WebServices.post: Error caught on POST: #{e}")
            end
        end
        
        def self.put(url, data: data=nil, resource: resource=nil)
            begin
                self.rest_call('PUT', url, data, resource)
            rescue Exception => e
                fail("puppet_x::CyberArk::WebServices.put: Error caught on PUT: #{e}")
            end
        end
        
        def self.patch(url, data: data=nil, resouce: resource=nil)
            begin
                self.rest_call('PATCH', url, data, resource)
            rescue Exception => e
                fail("puppet_x::CyberArk::WebServices.put: Error caught on PATCH: #{e}")
            end
        end
        
        def self.delete(url, data: data=nil, resource: resource=nil)
            begin
                self.rest_call('DELETE', url, data, resource)
            rescue Exception => e
                fail("puppet_x::CyberArk::WebServices.delete: Error caught on DELETE: #{e}")
            end
        end
        
            def self.get(url, data: data=nil, resource: resource=nil)
                #     def self.get(url, token, data=nil)
                Puppet.debug("GET!!!  resource = #{resource}")
                Puppet.debug("******** LOGIN username => #{resource[:login_username]}")
                Puppet.debug("******** base_url => #{resource['base_url']}")

                begin
                    self.rest_call('GET', url, data, resource: resource)
                rescue Exception => e
                    fail("puppet_x::CyberArk::WebServices.get: Error caught on GET: #{e}")
                end
            end
        
            def self.rest_call(action, url, data, resource)
                # Single method to make all calls to the respective RESTful API

                if resource 
                    Puppet.debug("Resource passed #{resource[:resource].parameters.keys}")
                    if resource[:resource].parameters[:base_url] != nil
                        Puppet.debug("Setting base_url to #{resource[:resource].parameters[:base_url].value}")
                        self.set_base_url(resource[:resource].parameters[:base_url].value)
                    end 
                    if resource[:resource].parameters[:certificate_file] != nil
                        Puppet.debug("Setting certificate_file to #{resource[:resource].parameters[:certificate_file].value}")
                        self.set_certificate_file(resource[:resource].parameters[:certificate_file].value)
                    end 
                end

                if base_url + "/" + url !~ URI::regexp
                    fail("puppet_x::CyberArk::WebServices.get: Must supply a valid URL and/or set environment variable CyberArk_PVWA_BaseURL")
                end

                uri = URI.parse(base_url + "/" + url)

                http = Net::HTTP.new(uri.host, uri.port)

                if uri.port == 443 or uri.scheme == 'https'
                    http.use_ssl = true
                    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
                    http.cert_store = OpenSSL::X509::Store.new
                    http.cert_store.set_default_paths
                    if certificate_file != ""
                        http.cert_store.add_file(certificate_file)
                    end
                else
                    http.use_ssl = false
                end

                if Puppet[:debug] == true
                    http.set_debug_output($stdout)
                end

                if action =~ /post/i
                    req = Net::HTTP::Post.new(uri.request_uri)
                elsif action =~ /logon/i
                    req = Net::HTTP::Post.new(uri.request_uri)
                elsif action =~ /patch/i
                    req = Net::HTTP::Patch.new(uri.request_uri)
                elsif action =~ /put/i
                    req = Net::HTTP::Put.new(uri.request_uri)
                elsif action =~ /delete/i
                    req = Net::HTTP::Delete.new(uri.request_uri)
                else
                    req = Net::HTTP::Get.new(uri.request_uri)
                end

                req.set_content_type('application/json')

                if action !~ /logon/i  && @@session_token.empty? 
                    Puppet.debug("Session Token not set, authenticating first")
                    self.web_service_logon(resource)
                    Puppet.debug("SessionToken=#{@@session_token}")
                end

                req.add_field('Authorization', "#{@@session_token}")

                req.body = data if data && valid_json?(data)

                Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Endpoint: #{uri.to_s}")
                Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Request: #{req.to_s}")

                Puppet.debug("before http.request")
                response = http.request(req)
                Puppet.debug("after http.request")

                Puppet.debug("webservices::#{calling_method}: REST API #{req.method} Response: #{response.inspect}")

                if req.method == 'GET'
                    return JSON.parse(response.body)
                else
                    return response
                end

                return response, jsonBody

            end

            def self.web_service_logon(resource)

                Puppet.debug("LOGON INVOKED!")

                data = {}
                endpoint_url = "/PasswordVault/WebServices/auth/Shared/RestfulAuthenticationService.svc/Logon"

                Puppet.debug(" #{resource[:resource].parameters[:use_shared_logon_authentication].value}")

                if resource[:resource].parameters[:use_shared_logon_authentication].value.to_s == "false"
                    Puppet.debug("Not using shared_logon_authentication")

                    endpoint_url = "/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon"

                    if resource[:resource].parameters[:login_username] && resource[:resource].parameters[:login_password]
                        data['username'] = resource[:resource].parameters[:login_username].value
                        data['password'] = resource[:resource].parameters[:login_password].value
                    else
                        fail("webservices::#{calling_method}: Unable to logon. Missing username/password")
                    end
                end

                response = self.rest_call("LOGON", endpoint_url, data.to_json, resource)
                Puppet.debug("Response => #{response.code}")
                if response.code == "200" 
                    result = JSON.parse(response.body)
                    if result.key?('LogonResult')
                        @@session_token = result['LogonResult']
                    elsif result.key?('CyberArkLogonResult')
                        @@session_token = result['CyberArkLogonResult']
                    else
                        fail("webservices::#{calling_method}: Unable to logon. No session token found!")
                    end
                else
                    fail("webservices::#{calling_method}: Unable to logon")
                end
            end

                
            def self.valid_json?(json)
                Puppet.debug(json)
                JSON.parse(json)
                return true
            rescue Exception => e
                fail("webservices::#{calling_method}: Unable to parse parameters passed in as valid JSON: #{e.message}")
                return false
            end

        end

    end

end