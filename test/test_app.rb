ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../app'

class RAOKTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  # Helper methods
  def session
    last_request.env['rack.session']
  end

  def admin_user
    session[:current_user] = 1 # this requires an 'admin' user in the database
  end

  def create_admin_user
    user_data = ['admin name',
                 'admin@test.com',
                 'admin',
                 BCrypt::Password.create('P4ssword')]
 
    @storage.add_user!(user_data)
  end

  def add_admin_user_posts
  end

  def setup
    @storage = Storage.new
    @storage.delete_all_data
  end

  def teardown
    @storage.delete_all_data
  end

  # Tests
  def test_signup_success
    message = '<p>Congrats admin name, your account was created'

    post '/signup', { username: 'admin',
                      password1: 'P4ssword',
                      password2: 'P4ssword',
                      name: 'admin name',
                      email: 'admin@test.com' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_passwords_dont_match
    message = '<p>Password unaccepted, repeat the same password twice'

    post '/signup', { username: 'admin',
                      password1: 'P4ssword',
                      password2: 'different password',
                      name: 'admin name',
                      email: 'admin@test.com' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_invalid_password
    message = '<p>Password must be 6 or more characters, including uppercase and lowercase letters and a number'

    post '/signup', { username: 'admin',
                      password1: 'password',
                      password2: 'password',
                      name: 'admin name',
                      email: 'admin@test.com' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message

    post '/signup', { username: 'admin',
                      password1: 'Password',
                      password2: 'Password',
                      name: 'admin name',
                      email: 'admin@test.com' }
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_signup_fail_user_exists
    create_admin_user
    message = '<p>Username is already taken, choose a new username'

    post '/signup', { username: 'admin',
                      password1: 'P4ssword',
                      password2: 'P4ssword',
                      name: 'admin name',
                      email: 'a@test.com' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_email_exists
    create_admin_user
    message = '<p>Email address is already registered'

    post '/signup', { username: 'username',
                      password1: 'P4ssword',
                      password2: 'P4ssword',
                      name: 'admin name',
                      email: 'admin@test.com' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_signin_success
    create_admin_user
    current_user = '1'
    message = '<p>admin is signed in!'

    post '/signin', { username: 'admin', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal session[:current_user], current_user
    assert_includes last_response.body, message
  end

  def test_signin_fail_invalid_credentials
    create_admin_user
    message = '<p>Invalid credentials'

    # user isn't found
    post '/signin', { username: 'fake-name', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message

    # wrong password
    post '/signin', { username: 'admin', password: 'password' }
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_can_view_profile

    # signin
    # current_user = '1'
    # request profile page (using current_user)
    # check if profile was saved
  end

  def test_can_edit_profile
 
    # signin
    # current_user = '1'
    # post updated profile data for current_user
    # check if updated profile was saved
  end
end
