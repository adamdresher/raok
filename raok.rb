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
  set :session_secrets, 'super secret'
  set :erb, escape_html: true
end

before do
  @db = DatabasePersistence.new(logger)
  @storage = Storage.new(db: @db)
  @user = User.new(db: @db)
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

    user_data = @user.profile(params)
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
    session[:current_user] = username
    session[:message] = "#{username} is signed in!"

    redirect '/'
  else
    session[:message] = "Invalid credentials"

    redirect '/signin'
  end
end

post '/signout' do
  username = session[:current_user]
  session[:message] = "#{username} is signed out"

  session.delete(:current_user)

  redirect '/'
end

get '/profile' do
  return_home_unless_signed_in

  @username = session[:current_user]
  @profile = @user.profile(@username)

  erb :profile, layout: :layout
end

get '/new-kindness' do
  return_home_unless_signed_in

  erb :new_kindness, layout: :layout
end

post '/new-kindness' do
  username = session[:current_user]
  description = params[:description]

  @user.add_post!(username, description)

  redirect '/user-kindnesses'
end

get '/user-kindnesses' do
  return_home_unless_signed_in

  username = session[:current_user]
  @posts = @user.posts(username)

  erb :user_kindnesses, layout: :layout
end

