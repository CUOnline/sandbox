require_relative '../sandbox_app'

require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/mini_test'
require 'rack/test'
require 'webmock/minitest'

# Turn on SSL for all requests
class Rack::Test::Session
  def default_env
    { 'rack.test' => true,
      'REMOTE_ADDR' => '127.0.0.1',
      'HTTPS' => 'on'
    }.merge(@env).merge(headers_for_env)
  end
end

class SandboxAppTest < Minitest::Test

  include Rack::Test::Methods

  def app
    SandboxApp
  end

  def setup
    WebMock.enable!
    WebMock.disable_net_connect!

    @canvas_params = {
      'ext_roles' => 'Administrator',
      'oauth_consumer_key' => app.send(:client_id),
      'lis_person_name_full' => 'Test Guy',
      'custom_canvas_user_id' => '1234'
    }
  end

  def test_get
    get '/'
    assert_equal 200, last_response.status
    assert_equal last_response.header["Content-Type"], 'text/xml'
  end

  def test_valid_post
    IMS::LTI::ToolProvider.any_instance.stubs(:valid_request?).returns(true)
    course_id = '123'
    sandbox_account_id = '456'
    app.settings.stubs(:sandbox_account_id).returns(sandbox_account_id)

    stub_request(:post, /accounts\/#{sandbox_account_id}\/courses/)
      .to_return(:body => {'id' => course_id}.to_json,
                 :headers => {'Content-Type' => 'application/json'})

    stub_request(:post, /courses\/#{course_id}\/enrollments/)
      .to_return(:body => {}.to_json,
                 :headers => {'Content-Type' => 'application/json'})

    post '/', @canvas_params

    assert_equal 200, last_response.status
    assert_match /Course Created/, last_response.body
    assert_equal "ALLOW-FROM https://ucdenver.test.instructure.com",
                 last_response.header["X-Frame-Options"]
  end

  def test_invalid_request_post
    IMS::LTI::ToolProvider.any_instance.stubs(:valid_request?).returns(false)

    post '/', @canvas_params

    assert_equal 403, last_response.status
    assert_match /not authorized/, last_response.body
    assert_equal "ALLOW-FROM https://ucdenver.test.instructure.com",
                 last_response.header["X-Frame-Options"]
  end

  def test_invalid_roles_post
    @canvas_params['ext_roles'] = 'Student'
    IMS::LTI::ToolProvider.any_instance.stubs(:valid_request?).returns(true)

    post '/', @canvas_params

    assert_equal 403, last_response.status
    assert_match /not authorized/, last_response.body
    assert_equal "ALLOW-FROM https://ucdenver.test.instructure.com",
                 last_response.header["X-Frame-Options"]
  end
end
