require 'bundler'
Bundler.require
require './main'
 

configure :development do
  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
end
configure :production do
  DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_YELLOW_URL'])
end



run Sinatra::Application