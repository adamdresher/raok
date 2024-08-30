require 'sinatra'
require 'tilt/erubis'
require 'bcrypt'
require 'pg'
require 'pry'
require 'pry-byebug'

require_relative 'lib/database_connection'
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
  also_reload 'lib/database_connection.rb'
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

MESSAGES =
  { username_taken: 'Username is already taken, choose a new username',
    email_taken: 'Email address is already registered',
    invalid_username: 'Username cannot contain spaces',
    invalid_email: 'Invalid email address',
    invalid_password1: 'Password must be 6 or more characters, including uppercase and lowercase letters and a number',
    invalid_password2: 'Password must be repeated twice',
    signin_first: 'Please sign in first',
    signout_first: 'Please sign out first',
    invalid_credentials: 'Invalid credentials',
    user_not_found: 'User does not exist',
    post_created: 'Your post has been created',
    post_deleted: 'Your post has been deleted',
    invalid_input: 'Invalid input' }.freeze

def check_signup_credentials(user_data)
  signup_status = []
  signup_status << MESSAGES[:username_taken] if @users.include?(username: user_data['username'])
  signup_status << MESSAGES[:email_taken] if @users.include?(email: user_data['email'])
  signup_status << MESSAGES[:invalid_username] unless valid_username?(user_data['username'])
  signup_status << MESSAGES[:invalid_email] unless valid_email?(user_data['email'])
  signup_status << MESSAGES[:invalid_password1] unless valid_password?(user_data['password1'])
  signup_status << MESSAGES[:invalid_password2] unless password_repeated?(user_data['password1'], user_data['password2'])

  signup_status = :valid if signup_status.empty?

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

  session[:message] = [ERROR_MESSAGE[:signout_first]]

  redirect '/'
end

def redirect_home_unless_signed_in
  return if signed_in?

  session[:message] = [ERROR_MESSAGE[:signin_first]]

  redirect '/'
end

def reference_current_user_as_you(usernames, username)
  usernames.prepend('you').delete(username) if usernames&.include?(username)

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

# def add_dots(line)
#   line = (line + (' ' * (PREVIEW_LENGTH - line.length)))
#   line[-3..-1] = '...'
#   line
# end
# 
# def split_word(word, length)
#   substrings = []
# 
#   until word.empty? do
#     substrings << word.slice!(0, length - 1)
#   end
# 
#   substrings
# end

helpers do
  def list_likes_from(usernames, current_username)
    usernames = reference_current_user_as_you(usernames, current_username)
    count = usernames.size

    format_likes_from(usernames, count)
  end

#   def preview(description)
#     preview = []
#     line = ''
#     words = description.split
# 
#     words.each_with_index do |word, idx|
#       if idx == 0 && word.length <= PREVIEW_LENGTH # first word and fits in one line
#         line << word
#       elsif (line + word).length <= PREVIEW_LENGTH - 1 # word can be added on the same line
#         line << word.prepend(' ')
#       elsif word.length > PREVIEW_LENGTH # word is longer than a line
#         preview << line.clone unless line.empty?
# 
#         substrings = split_word(word, PREVIEW_LENGTH)[..4]
#         line << substrings.pop # ensures the last substring is added later
# 
#         substrings.each { |substring| preview << substring }
#       else # line is full
#         preview << line.clone
#         line.clear << word
#       end
# 
#       preview << line if idx == (words.size - 1) # adds line to preview if it has the last word
#     end
# 
#     if preview.length > PREVIEW_HEIGHT
#       preview[PREVIEW_HEIGHT] = add_dots(preview[PREVIEW_HEIGHT])
#     end
# 
#     preview[..PREVIEW_HEIGHT].join(' ')
#   end

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
    session[:message] = [MESSAGES[:invalid_credentials]]

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
    session[:message] = [ERROR_MESSAGE[:user_not_found]]

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
  session[:message] = [MESSAGES[:post_created]]
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
  session[:message] = [MESSAGES[:post_deleted]]
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
    session[:message] = [MESSAGES[:invalid_input]]

    redirect '/'
  end

  erb :query_results, layout: :layout
end
