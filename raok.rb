require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'bcrypt'
require 'pg'
require 'pry'
require 'pry-byebug'

require_relative 'database-persistence'

configure do
  enable :sessions
  set :session_secrets, 'super secret'
  set :erb, escape_html: true
end

before do
  @storage = DatabasePersistence.new(logger)
end

after do
  @storage.disconnect
end

# Route helper methods
def logged_in?
  session[:current_user]
end

# can't help thinking about refactoring,
# but holding off until I cover all/most functionality
#
# def return_home_unless(logged_in) # use logged_in? or !logged_in?
#   if logged_in
#     session[:message] = "Please sign out before creating a new account"
#   else
#     session[:message] = "Please sign in first"
#   end
#
#   redirect '/'
# end

# def user_exists?(username)
#   # session[:users][username]
#   @storage.user_exists?(username)
# end

def valid_credentials?(username, password)
  return false unless @storage.user_exists?(username)

  encrypted_password = @storage.encrypted_password_for(username)
  decrypted_password = BCrypt::Password.new(encrypted_password)

  decrypted_password == password
end

# Routes
get '/' do
  session[:users] ||= {}
  session[:posts] ||= []
  @posts = session[:posts]

  p "users are: #{session[:users]}"
  p "current user is: #{session[:current_user]}"
  p "posts are: #{@posts}"


  erb :index, layout: :layout
end

get '/signup' do
  if logged_in?
    session[:message] = "Please sign out before creating a new account"

    redirect '/'
  end

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

    name = params[:name].strip
    email = params[:email].strip
    username = params[:username]
    password = BCrypt::Password.create(password1)

    user_data = [name, email, username, password]
    @storage.add_user!(user_data)

    redirect '/'
  end
end

get '/signin' do
  erb :signin, layout: :layout
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if @storage.user_exists?(username) && valid_credentials?(username, password)
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
  unless logged_in?
    session[:message] = "Please sign in first"

    redirect '/'
  end

  @username = session[:current_user]
  @profile = @storage.user_profile(@username)

  erb :profile, layout: :layout
end

get '/new-kindness' do
  unless logged_in?
    session[:message] = "Please sign in first"

    redirect '/'
  end

  erb :new_kindness, layout: :layout
end

post '/new-kindness' do
  user = session[:current_user]
  post = { user: user, description: params[:description] }
  session[:posts] << post

  p user
  p post

  redirect '/user-kindnesses'
end

get '/user-kindnesses' do
  unless logged_in?
    session[:message] = "Please sign in first"

    redirect '/'
  end

  username = session[:current_user]
  @posts = session[:posts].select { |post| post[:user] == username }

  erb :user_kindnesses, layout: :layout
end

