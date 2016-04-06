require 'bundler/setup'
require 'wolf_core'
require 'ims/lti'
require 'oauth/request_proxy/rack_request'

class SandboxApp < WolfCore::App
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

        url = "accounts/#{settings.sandbox_account_id}/courses"
        payload = {
          'course' => {
            'name' => "sandbox_#{params['lis_person_name_full'].gsub(/ /, '_')}"
          }
        }
        course = canvas_api(:post, url, {:payload => payload})

        url = "courses/#{course['id']}/enrollments"
        payload = {
          'enrollment' => {
            'user_id' => params['custom_canvas_user_id'],
            'type' => 'TeacherEnrollment'
          }
        }
        canvas_api(:post, url, {:payload => payload})

        @success = true
      end
    end

    headers 'X-Frame-Options' => "ALLOW-FROM #{settings.canvas_url}"
    slim :index, :layout => false
  end

  get '/' do
    headers 'Content-Type' => 'text/xml'
    slim :lti_config, :layout => false
  end
end
