require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  set :erb, escape_html: true
end

get '/' do
  'Hello world'
end

get '/test' do
  erb :index, layout: :layout
end

