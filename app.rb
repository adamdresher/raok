require 'sinatra'
require 'tilt/erubis'
require 'bcrypt'
require 'pg'
require 'pry'
require 'pry-byebug'

require_relative 'lib/database-connection'
require_relative 'lib/users'
require_relative 'lib/user'
require_relative 'lib/posts'

# must contain a lowercase letter, uppercase letter, and a number
VALID_PASSWORD_PATTERN = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/

configure do
  enable :sessions
  set :session_secret, 'WTu3&CEJn@vG@9AdxLAV833R!rYTZ^2tiejq4kWh8UEsRmDZXa&nyvdWz$#&S#wT'
  # set :session_secret, ENV['SESSION_SECRET']
  set :erb, escape_html: true
  set :last_route, '/' # sets the last route for redirecting to previous route
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'lib/database-connection.rb'
  also_reload 'lib/storage.rb'
  also_reload 'lib/user.rb'
end

before do
  user_id = session[:current_user]
  @users = Users.new(logger: logger)
  @posts = Posts.new(logger: logger)
  @user = User.new(user_id: user_id, logger: logger) if signed_in?
end

after do
  @users.disconnect
  @posts.disconnect
  @user.disconnect if signed_in?
end

# Route helper methods

def check_signup_credentials(user_data)
  signup_status = []
  signup_status << 'Username is already taken, choose a new username' if @users.include?(username: user_data['username'])
  signup_status << 'Email address is already registered' if @users.include?(email: user_data['email'])
  signup_status << 'Username cannot contain spaces' unless valid_username?(user_data['username'])
  signup_status << 'Invalid email address' unless valid_email?(user_data['email'])
  signup_status << 'Password must be 6 or more characters, including uppercase and lowercase letters and a number' unless valid_password?(user_data['password1'])
  signup_status << 'Password must be repeated twice' unless password_repeated?(user_data['password1'], user_data['password2'])

  if signup_status.empty?
   signup_status = :valid
  end

  signup_status
end

def format_likes_from(users, count)
  case count
  when 0   then 'No likes yet, be the first!'
  when 1   then "Liked by #{users.first}"
  when 2   then "Liked by #{users.first} and #{users.last}"
  when 3   then "Liked by #{users.first}, #{users[1]}, and one other"
  when 4.. then "Liked by #{users.first}, #{users[1]} and #{count - 2} others"
  end
end

def list_contains_user?(usernames, current_username)
  usernames&.include?(current_username)
end

def password_repeated?(password1, password2)
  password1 == password2
end

def redirect_home_if_signed_in
  return unless signed_in?

  session[:message]  ['Please sign out first']

  redirect '/'
end

def redirect_home_unless_signed_in
  return if signed_in?

  session[:message] = ['Please sign in first']

  redirect '/'
end

def reference_current_user_as_you(usernames, current_username)
  if usernames&.include?(current_username)
    usernames.prepend('you').delete(current_username)
  end

  usernames
end

def signed_in?
  session[:current_user]
end

def user_profile(params)
  name = params[:name].strip
  email = params[:email].strip
  username = params[:username]
  password = BCrypt::Password.create(params[:password1])

  [name, email, username, password]
end

def valid_signin?(username, password)
  return false unless @users.include?(username: username)

  encrypted_password = @users.encrypted_password_for(username)
  decrypted_password = BCrypt::Password.new(encrypted_password)

  decrypted_password == password
end

def valid_email?(email)
  email.match? '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'
end

def valid_password?(password)
   password.match?(VALID_PASSWORD_PATTERN)
end

def valid_username?(username)
  username.split.size == 1
end

helpers do
  def list_likes_from(usernames, current_username)
    usernames = reference_current_user_as_you(usernames, current_username)
    count = usernames.size

    format_likes_from(usernames, count)
  end

  def user_likes?(post)
    signed_in? && post.liked_by.include?(@user.username)
  end
end

# Routes

get '/' do
  settings.last_route = '/'
  @public_posts = @posts.all

  erb :index, layout: :layout
end

get '/signup' do
  redirect_home_if_signed_in

  erb :signup, layout: :layout
end

post '/signup' do
  signup_credentials_status = check_signup_credentials(params)

  if signup_credentials_status == :valid
    session[:message] = ["Congrats #{params[:name]}, your account was created"]

    @users.add!(user_profile(params))

    redirect '/'
  else
    session[:message] = signup_credentials_status
  
    redirect '/signup'
  end
end

get '/signin' do
  redirect_home_if_signed_in

  erb :signin, layout: :layout
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if valid_signin?(username, password)
    user_id = @users.id_for(username)
    @user = User.new(user_id: user_id, logger: logger)
    session[:current_user] = user_id
    session[:message] = ["#{username} is signed in!"]

    redirect '/'
  else
    session[:message] = ['Invalid credentials']

    redirect '/signin'
  end
end

post '/signout' do
  session[:message] = ["#{@user.username} is signed out"]
  @user = nil

  session.delete(:current_user)

  redirect '/'
end

get '/user/:user_id' do
  unless @users.exists?(user_id: params[:user_id])
    session[:message] = ['User does not exist']

    redirect '/'
  end

  @user = User.new(user_id: params[:user_id], logger: logger)
  @selected_posts = @posts.from_user(@user.id)
  @is_profile_from_current_user = (session[:current_user] == @user.id)

  settings.last_route = "/user/#{@user.id}"

  erb :profile, layout: :layout
end

get '/user/:user_id/edit' do
  redirect_home_unless_signed_in

  erb :edit_profile, layout: :layout
end

post '/user/:user_id/edit' do
  session[:message] = ["#{@user.username}'s profile has been updated"]
  new_name = params[:name]
  new_email = params[:email]

  @user.update_profile!(new_name, new_email)

  redirect "/user/#{@user.id}"
end

post '/user/:user_id/delete' do
  session[:message] = ["#{@user.username} has been deleted"]
  session.delete(:current_user)

  @users.delete!(@user)
  @user = nil

  redirect '/'
end

get '/kindness/new' do
  redirect_home_unless_signed_in

  erb :new_post, layout: :layout
end

post '/kindness/new' do
  session[:message] = ['Your post has been created']
  @user.add_post!(params[:description])

  redirect settings.last_route
end

get '/kindness/:post_id' do
  id = params[:post_id].to_i
  settings.last_route = "/kindness/#{id}"
  @post = @posts.with_id(id)
  @is_user_created_post = (@user&.username == @post.posted_by)

  erb :post, layout: :layout
end

post '/kindness/:post_id/delete' do
  session[:message] = ['Your post has been deleted']
  id = params[:post_id].to_i

  @user.delete_post!(id)

  redirect settings.last_route
end

post '/kindness/:post_id/like' do
  post_id = params[:post_id].to_i
  post = @posts.with_id(post_id)

  @user.toggle_like!(post)

  redirect "/kindness/#{post_id}"
end

post '/kindness/:post_id/comment' do
  post_id = params[:post_id].to_i
  comment = params['new-comment']

  @user.add_comment!(post_id, comment)

  redirect "/kindness/#{post_id}"
end

get '/query/:query_type&:query' do
  @query_type = params[:query_type]
  @query = params[:query]

  if @query_type == 'username'
    user_ids = @users.ids_for_similar(@query)
    @selected_users = user_ids.map { |user_id| User.new(user_id: user_id) }
  elsif @query_type == 'hashtag'
    @selected_posts = @posts.with_hashtag(@query)
  else
    session[:message] = ['Invalid input']

    redirect '/'
  end

  erb :query_results, layout: :layout
end
