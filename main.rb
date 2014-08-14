require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'slim'
require 'data_mapper'
require 'dm-migrations'
require 'dm-validations'
require 'omniauth-identity'
require 'dm-ar-finders'
require './sinatra/auth'

#INICIALIZERS




configure :development do
    DataMapper.auto_upgrade!
end



#omniauth initializer

use Rack::Session::Pool
use OmniAuth::Builder do
  provider :identity, :fields => [:email], on_failed_registration: lambda { |env|
      status, headers, body = call env.merge("PATH_INFO" => '/register')
    }
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }
end




DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")


class Identity
  include DataMapper::Resource
  include OmniAuth::Identity::Models::DataMapper

  property :id,              Serial
  property :email,           String
  property :password_digest, Text

  attr_accessor :password_confirmation

  validates_uniqueness_of :email
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
end


class User
  include DataMapper::Resource


  property :id,           Serial
  property :email,        String
  property :username,     String
  property :password,     String
  property :name,         String
  property :lastname,     String
  property :created_at,   DateTime


  has n, :corporations

end


class Corporation
  include DataMapper::Resource
  property :id,             Serial
  property :name,           String
  property :description,    Text
  property :status,         String
  property :completed_at,   DateTime
  has n, :projects
  belongs_to :user
end

class Project
  include DataMapper::Resource
  property :id,             Serial
  property :name,           String, :required => true
  property :description,    Text
  property :status,         String
  property :completed_at,           DateTime
  has 1, :budget 
  belongs_to :client
  belongs_to :corporation
end

class Budget
  include DataMapper::Resource
  property :id,             Serial
  property :amount,         Integer
  property :date,           DateTime
  belongs_to :project
end
 
class Client
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  has n, :advpayments
  has n, :projects

end

class Advpayment
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       String
  belongs_to :client
  belongs_to :project

end

class Supplier
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  has n, :payments
  has n, :quotes

end

class Quote
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer
  property :date,     DateTime
  belongs_to :supplier
  belongs_to :project
end

class Payment
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer
  property :date,         DateTime
  belongs_to :supplier
  belongs_to :project
end

class Purchase
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer
  property :date,         DateTime
  belongs_to :project

end

DataMapper.finalize


#HOME PONE A TODOS LOS USUARIOS 

get '/' do
  protected!
  @users = User.all(:order => [:name])
  slim :index
end






# CUANDO JALA EL GATILLO DE POST AGREGA Corporation Y REGRESA A HOME

post '/:id' do
  User.get(params[:id]).corporations.create params['corporation']
  redirect to('/')
end

delete '/corporation/:id' do
  Corporation.get(params[:id]).destroy
  redirect to('/')
end




put '/corporation/:id' do
  corporation = Corporation.get params[:id]
  corporation.completed_at = corporation.completed_at.nil? ? Time.now : nil
  corporation.save
  redirect to('/')
end


#CUANDO JALA EL GATILLO DE POST AGREGA USER Y LOS BORRA

post '/new/user' do
  User.create params['user']
  redirect to('/')
end
 
delete '/user/:id' do
  User.get(params[:id]).destroy
  redirect to('/')
end


  






