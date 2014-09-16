require 'bundler'
Bundler.require
require './main'
 


DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_AMBER_URL'])




run Sinatra::Application