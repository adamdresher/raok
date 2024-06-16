require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secrets, 'super secret'
  set :erb, escape_html: true
end

get '/' do
  p session[:users]
  erb :index, layout: :layout
end

get '/signup' do
  erb :signup, layout: :layout
end

post '/signup' do
  username = params[:username].strip
  password1 = params[:password1]
  password2 = params[:password2]

  session[:users] ||= {}
  session[:users][username] = { name:      params[:name].strip,
                                email:     params[:email].strip,
                                username:  username,
                                password1: password1,
                                password2: password2 }


  if password1 != password2
    session[:message] = 'invalid credentials'
  else
    session[:message] = 'account created'
  end

  redirect '/'
end

get '/signin' do
  erb :signin, layout: :layout
end

post '/signin' do
  username = params[:username]
  password = params[:password]

  if password == session[:users][username][:password1]
    session[:current_user] = username
    session[:message] = "#{username} is signed in!"

    redirect '/'
  else
    session[:message] = "Invalid credentials"

    erb :signin, layout: :layout
  end
end

post '/signout' do
  username = session[:current_user]
  session[:message] = "#{username} is signed out"

  session[:current_user] = {}

  redirect '/'
end

