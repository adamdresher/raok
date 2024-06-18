require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secrets, 'super secret'
  set :erb, escape_html: true
end

get '/' do
  session[:users] ||= {}
  session[:current_user] ||= {}

  p "users are: #{session[:users]}"
  p "current user is: #{session[:current_user]}"

  erb :index, layout: :layout
end

get '/signup' do
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

  p "users are: #{session[:users]}"
  p "current user is: #{session[:current_user]}"

  if session[:users][username] && password == session[:users][username][:password1]
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

  session[:current_user] = ''

  redirect '/'
end

get '/profile' do
  @username = session[:current_user]
  @profile = session[:users][@username].reject do |attribute, _|
    attribute.match? /password/
  end

  erb :profile, layout: :layout
end
