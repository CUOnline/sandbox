class SandboxApp < Wolf::Base
  set :root, File.dirname(__FILE__)
  self.setup

  post '/' do
    begin
      if params['oauth_consumer_key'] == settings.consumer_key &&
        (params['ext_roles'].include?('Administrator') ||
         params['ext_roles'].include?('Instructor'))

        # Verify OAuth signature
        provider = IMS::LTI::ToolProvider.new(settings.consumer_key, settings.shared_secret, params)
        @authorized = provider.valid_request?(request)

        url = "#{settings.api_base}/accounts/#{settings.sandbox_account_id}/courses"
        payload = {
          'course' => {
            'name' => "sandbox_#{params['lis_person_name_full'].gsub(/ /, '_')}"
          }
        }
        response = JSON.parse(RestClient.post(url, payload, auth_header))

        url = "#{settings.api_base}/courses/#{response['id']}/enrollments"
        payload = {
          'enrollment' => {
            'user_id' => params['custom_canvas_user_id'],
            'type' => 'TeacherEnrollment'
          }
        }
        response = JSON.parse(RestClient.post(url, payload, auth_header))

        @success = true
      end
    rescue Exception => e
      settings.error_log.fatal(e.to_s)
      settings.error_log.fatal(e.backtrace.join("\n\t"))
    end

    headers 'X-Frame-Options' => "ALLOW-FROM #{settings.canvas_url}"
    slim :index, :layout => false
  end

  get '/' do
    headers 'Content-Type' => 'text/xml'
    slim :lti_config, :layout => false
  end
end
