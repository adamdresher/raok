require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secrets, 'super secret'
  set :erb, escape_html: true
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

def user_exists?(username)
  session[:users][username]
end

def valid_credentials?(username, password)
  password == session[:users][username][:password1]
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
  username = params[:username].strip
  password1 = params[:password1]
  password2 = params[:password2]

  if password1 != password2
    session[:message] = 'Invalid credentials'

    redirect '/signup'
  else
    session[:message] = "Congrats #{params[:name]}, your account was created"
    session[:users][username] = { name:      params[:name].strip,
                                  username:  username,
                                  email:     params[:email].strip,
                                  password1: password1,
                                  password2: password2 }

    redirect '/'
  end
end

get '/signin' do
  erb :signin, layout: :layout
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if user_exists?(username) && valid_credentials?(username, password)
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
  @profile = session[:users][@username].reject do |attribute, _|
    attribute.match? /password/
  end

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

