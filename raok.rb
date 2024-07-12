require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'bcrypt'
require 'pg'
require 'pry'
require 'pry-byebug'

require_relative 'database-persistence'
require_relative 'storage'
require_relative 'user'

configure do
  enable :sessions
  set :session_secret, 'WTu3&CEJn@vG@9AdxLAV833R!rYTZ^2tiejq4kWh8UEsRmDZXa&nyvdWz$#&S#wT'
  set :erb, escape_html: true
end

before do
  user_id = session[:current_user]
  @db = DatabasePersistence.new(logger)
  @storage = Storage.new(@db)
  @user = User.new(user_id, @db) if signed_in?
end

after do
  @db.disconnect
end

# Route helper methods
def signed_in?
  session[:current_user]
end

def return_home_if_signed_in
  if signed_in?
    session[:message] = "Please sign out first"

    redirect '/'
  end
end

def return_home_unless_signed_in
  if !signed_in?
    session[:message] = "Please sign in first"

    redirect '/'
  end
end

def valid_credentials?(username, password)
  return false unless @storage.user_exists?(username)

  encrypted_password = @storage.encrypted_password_for(username)
  decrypted_password = BCrypt::Password.new(encrypted_password)

  decrypted_password == password
end

def user_profile(params)
  name = params[:name].strip
  email = params[:email].strip
  username = params[:username]
  password = BCrypt::Password.create(params[:password1])

  [name, email, username, password]
end

helpers do
  def format_likes_from(users, current_user)
    if current_user && users.include?(current_user)
      users.delete(current_user)
      current_user = 'you'
      users.prepend(current_user)
    end
    count = users.class == Array ? users.size : 0

    case count
    when 0   then 'No likes yet, be the first!'
    when 1   then "Liked by #{users.first}"
    when 2   then "Liked by #{users.first} and #{users.last}"
    when 3   then "Liked by #{users.first}, #{users[1]}, and one other"
    when 4.. then "Liked by #{users.first}, #{users[1]} and #{count - 2} others"
    end
  end

  def user_likes?(post)
    post['liked_by'] && @user && post['liked_by'].include?(@user.username)
  end
end

# Routes
get '/' do
  @posts = @storage.all_posts

  erb :index, layout: :layout
end

get '/signup' do
  return_home_if_signed_in

  erb :signup, layout: :layout
end

post '/signup' do
  password1 = params[:password1]
  password2 = params[:password2]

  if password1 != password2
    session[:message] = 'Invalid credentials'

    redirect '/signup'
  else
    session[:message] = "Congrats #{params[:name]}, your account was created"

    user_data = user_profile(params)
    @storage.add_user!(user_data)

    redirect '/'
  end
end

get '/signin' do
  return_home_if_signed_in

  erb :signin, layout: :layout
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    user_id = User.id(username, @db)
    @user = User.new(user_id, @db)

    session[:current_user] = user_id
    session[:message] = "#{username} is signed in!"

    redirect '/'
  else
    session[:message] = "Invalid credentials"

    redirect '/signin'
  end
end

post '/signout' do
  session[:message] = "#{@user.username} is signed out"

  @user = nil

  session.delete(:current_user)

  redirect '/'
end

get '/user' do
  return_home_unless_signed_in

  @username = @user.username
  @profile = @user.profile
  @posts = @user.posts

  erb :profile, layout: :layout
end

get '/user/edit' do
  return_home_unless_signed_in

  @username = @user.username
  @profile = @user.profile
  @profile.reject! { |k, v| ['id', 'username'].include? k }

  erb :edit_profile, layout: :layout
end

post '/user/edit' do
  session[:message] = "#{@user.username}'s profile has been updated"
  old_name = @user.profile['name']
  old_email = @user.profile['email']
  new_name = params[:name]
  new_email = params[:email]

  @user.update_profile!(old_name, old_email, new_name, new_email)

  redirect '/user'
end

post '/user/delete' do
  session[:message] = "#{@user.username} has been deleted"

  @storage.delete_user!(@user)
  @user = nil

  session.delete(:current_user)

  redirect '/'
end

get '/kindness/new' do
  return_home_unless_signed_in

  erb :new_kindness, layout: :layout
end

post '/kindness/new' do
  session[:message] = "Your post has been created"
  username = @user.username
  description = params[:description]

  @user.add_post!(username, description)

  redirect '/'
end

get '/kindness/:kindness_id' do
  id = params[:kindness_id].to_i

  @kindness = @storage.post(id)
  @user_created_kindness = (@user && @user.username == @kindness['posted_by'])

  erb :kindness, layout: :layout
end

post '/kindness/:kindness_id/delete' do
  session[:message] = "Your post has been deleted"
  id = params[:kindness_id].to_i

  @user.delete_post!(id)

  redirect '/'
end

post '/kindness/:kindness_id/like' do
  post_id = params[:kindness_id].to_i

  @user.toggle_like!(post_id)

  redirect '/'
end

post '/kindness/:kindness_id/comment' do
  post_id = params[:kindness_id].to_i
  comment = params['comment']

  @user.add_comment!(post_id, comment)

  redirect '/'
end
