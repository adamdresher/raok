require 'simplecov'
SimpleCov.start

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

  def create_user(name: 'name', email: 'email@test.com', username: 'username', password: 'P4ssword')
    user_data = [name,
                 email,
                 username,
                 BCrypt::Password.create(password)]
 
    @users.add!(user_data)
  end

  def signin_user(current_user: 1)
    { "rack.session" => { current_user: current_user } }
  end

  def create_post(user_id: 1, description: 'post description')
    user = User.new(user_id: user_id)

    user.add_post!(description)
  end

  def setup
    @users = Users.new
  end

  def teardown
    @users.delete_all_data
  end

  # Tests
  
  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h1>Random Acts of Kindness'
  end

  def test_signup_success
    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"] # redirects for 302 status code

    assert_includes last_response.body, '<p>Congrats name, your account was created'
  end

  def test_signup_fail_passwords_dont_match
    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'different password' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>Password unaccepted, repeat the same password twice'
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

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, message
  end

  def test_signup_fail_user_exists
    create_user

    post '/signup', { name: 'name',
                      email: 'new_email@test.com',
                      username: 'username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>Username is already taken, choose a new username'
  end

  def test_signup_fail_email_exists
    create_user

    post '/signup', { name: 'name',
                      email: 'email@test.com',
                      username: 'new_username',
                      password1: 'P4ssword',
                      password2: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>Email address is already registered'
  end

  def test_signin_success
    create_user

    post '/signin', { username: 'username', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_equal session[:current_user], '1'
    assert_includes last_response.body, '<p>username is signed in!'
  end

  def test_signin_fail_invalid_credentials
    create_user
    flash_message = '<p>Invalid credentials'

    # username isn't found
    post '/signin', { username: 'invalid-username', password: 'P4ssword' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, flash_message

    # wrong password
    post '/signin', { username: 'username', password: 'password' }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, flash_message
  end

  def test_can_view_profile
    create_user

    get '/user/1', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>username'
    assert_includes last_response.body, '<p><b>+'
  end

  def test_can_edit_profile
    create_user
    updated_user_profile = { name: 'new name', email: 'new-email@test.com' }

    get '/user/1/edit', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, '="submit">Delete Account'

    post '/user/1/edit', updated_user_profile

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, "<p>username's profile has been updated"
  end

  def test_delete_user
    create_user

    post '/user/1/delete', {}, signin_user

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>username has been deleted'
  end

  def test_view_other_user_profile_while_signed_out
    create_user
    create_post

    get '/user/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>username'
    assert_includes last_response.body, '<p>post description'
  end

  def test_view_other_user_profile_while_signed_in
    create_user
    create_post
    create_user(name: 'Mr Cat', email: 'cat@nd-friends.com', username: 'cat', password: 'lanna-music')

    get '/user/1', {}, signin_user(current_user: 2)

    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>username'
    assert_includes last_response.body, '<p>post description'
  end

  def test_add_post
    create_user
    description = 'post description'

    get '/kindness/new', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, '="kindness">Describe your'

    post '/kindness/new', { description: description }

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>Your post has been created'
    assert_includes last_response.body, description
  end

  def test_view_post
    create_user
    create_post
    description = 'post description'

    get '/', {}, signin_user

    assert_includes last_response.body, description

    get '/user/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, description

    get '/kindness/1'

    assert_equal 200, last_response.status
    assert_includes last_response.body, description
  end

  def test_delete_post
    create_user
    create_post

    post '/kindness/1/delete', {}, signin_user

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, '<p>Your post has been deleted'
    refute_includes last_response.body, '<p>post description'
  end

  def test_like_post
    create_user
    create_post
    create_user(name: 'Mr Cat', email: 'cat@nd-friends.com', username: 'cat', password: 'lanna-music')

    get '/kindness/1', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'like-off.png'

    post '/kindness/1/like'

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, 'like-on.png'

    get '/kindness/1', {}, signin_user(current_user: 2)

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'like-off.png'

    post '/kindness/1/like'

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, 'like-on.png'

    post '/kindness/1/like'

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, 'like-off.png'
  end

  def test_comment_on_post
    create_user
    create_post
    create_user(name: 'Mr Cat', email: 'cat@nd-friends.com', username: 'cat', password: 'lanna-music')
    comment = 'a comment'
    another_comment = 'another comment'

    post '/kindness/1/comment', {'new-comment' => comment }, signin_user

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, comment

    post '/kindness/1/comment', {'new-comment' => another_comment }, signin_user(current_user: 2)

    assert_equal 302, last_response.status
    get last_response["Location"]

    assert_includes last_response.body, another_comment
  end

  def test_search_for_user
    create_user
    create_user(username: 'Mr Cat', email: 'cat@nd-friends.com', username: 'cat', password: 'lanna-music')
    create_post
    create_post(user_id: 2, description: 'I love Chiang Mai!')

    get '/query/username&cat', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'cat'
  end

  def test_search_for_posts_by_hashtag
    create_user
    create_post
    create_post(description: "another post #new-tag")

    get '/query/hashtag&new-tag', {}, signin_user

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'another post'
  end
end
