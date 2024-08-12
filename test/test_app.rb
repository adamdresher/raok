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
 
  # unused method
  # def first_user_session
  #   session[:current_user] = 1 # this requires an 'admin' user in the database
  # end

  def create_user(name: 'name', email: 'email@test.com', username: 'username', password: 'P4ssword')
    user_data = [name,
                 email,
                 username,
                 BCrypt::Password.create(password)]
 
    @storage.add_user!(user_data)
  end

  def signin_user(username: 'username', password: 'P4ssword', current_user: 1)
    { "rack.session" => { username: username,
                          password: password,
                          current_user: current_user }}
  end

  def add_user_posts
  end

  def setup
    @storage = Storage.new
    @storage.delete_all_data
  end

  def teardown
    @storage.delete_all_data
  end

  # Tests
  
  def test_index
    title = 'Random Acts of Kindness'

    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, title
  end

  def test_signup_success
    message = '<p>Congrats name, your account was created'

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_passwords_dont_match
    message = '<p>Password unaccepted, repeat the same password twice'

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'different password' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_invalid_password
    message = '<p>Password must be 6 or more characters, including uppercase and lowercase letters and a number'

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'password',
                      password2: 'password' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'Password',
                      password2: 'Password' }
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_signup_fail_user_exists
    create_user
    message = '<p>Username is already taken, choose a new username'

    post '/signup', { name: 'name',
                      email: 'new_email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, message
  end

  def test_signup_fail_email_exists
    create_user
    message = '<p>Email address is already registered'

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'new_username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_signin_success
    create_user
    current_user = '1'
    message = '<p>username is signed in!'

    post '/signin', { username: 'username', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal session[:current_user], current_user
    assert_includes last_response.body, message
  end

  def test_signin_fail_invalid_credentials
    create_user
    message = '<p>Invalid credentials'

    # username isn't found
    post '/signin', { username: 'invalid-username', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message

    # wrong password
    post '/signin', { username: 'username', password: 'password' }
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_can_view_profile
    create_user
    username = 'username'
    new_post_icon = '+'

    get '/user/1', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, username
    assert_includes last_response.body, new_post_icon
  end

  def test_can_edit_profile
    create_user
    button = 'Delete Account'
    updated_user_profile = { name: 'new name', email: 'new-email@test.com' }

    get '/user/edit', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, button

    post '/user/edit', updated_user_profile
    # get last_response["Location"] # this isn't necessary, but not sure why

    assert_equal 302, last_response.status
    get '/user/edit'
    assert_includes last_response.body, 'new name'
  end
end
