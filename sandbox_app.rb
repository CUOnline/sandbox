require 'bundler/setup'
require 'wolf_core'
require 'ims/lti'
require 'oauth/request_proxy/rack_request'

class SandboxApp < WolfCore::App
  set :root, File.dirname(__FILE__)
  set :views, ["#{root}/views", settings.base_views]

  post '/' do
    if valid_lti_request?(request, params) &&
      (params['ext_roles'].include?('Administrator') ||
       params['ext_roles'].include?('Instructor'))

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

      @status = 200
    else
      @status = 403
    end

    status @status
    headers 'X-Frame-Options' => "ALLOW-FROM #{settings.canvas_url}"
    slim :index, :layout => false
  end

  get '/' do
    headers 'Content-Type' => 'text/xml'
    slim :lti_config, :layout => false
  end
end
