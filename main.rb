require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'slim'
require 'data_mapper'
require 'dm-migrations'
require 'dm-validations'
require 'omniauth-identity'
require 'omniauth-twitter'
require 'dm-ar-finders'
require './sinatra/auth'

#INICIALIZERS




configure :development do
    DataMapper.auto_upgrade!
end




#omniauth initializer

use Rack::Session::Pool
use OmniAuth::Builder do
  #IDENTITY
  provider :identity, :fields => [:email], model: User, on_failed_registration: lambda { |env|
      status, headers, body = call env.merge("PATH_INFO" => '/register')
    }
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    #TWITTER
  provider :twitter, 'dpGgrLpsjZl94CwwdykqoABuU', 'YJlE5EN36opAZRKgsx4lbHToaoz0h3RjPAmzEDHLrfUFGZyAjW'

end




DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")


class Authentication
  include DataMapper::Resource

  property :id,           Serial
  property :provider,     String
  property :uid,          String
  property :created_at,   DateTime
  property :updated_at,   DateTime

  belongs_to :user

  def self.find_with_omniauth(auth)
    authentication = Authentication.all.first(uid: auth["uid"], provider: auth["provider"])
  end
 
  def self.create_with_omniauth(auth)
    create! do |authentication|
    
      authentication.uid = auth["uid"]
      authentication.provider = auth["provider"]  
  
    end
  end

end


class User
  include DataMapper::Resource
  include OmniAuth::Identity::Models::DataMapper

  property :id,           Serial
  property :email,        String 
  property :username,     String
  property :password_digest,     Text 
  property :name,         String
  property :lastname,     String
  property :created_at,   DateTime

  attr_accessor :password_confirmation

  validates_presence_of :email
  validates_uniqueness_of :email
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  
  def self.create_with_omniauth(auth)
    create! do |user|
    
      user.email = auth["info"]["email"]
    end
  end

  has n, :authentications
  has n, :corporations
end
  
class Corporation
  include DataMapper::Resource
  property :id,             Serial
  property :name,           Integer, default: 0 # es string inicial ahora integer
  property :description,    Text
  property :status,         String
  property :completed_at,   DateTime
  has n, :projects
  has n, :clients
  belongs_to :user
end

class Client
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String
  has n, :advpayments
  has n, :projects

end

class Project
  include DataMapper::Resource
  property :id,             Serial
  property :name,           String, required: true
  property :description,    Text
  property :status,         String
  property :completed_at,           DateTime
  has n, :budgets 
  belongs_to :client
  belongs_to :corporation
end

class Budget
  include DataMapper::Resource
  property :id,             Serial
  property :amount,         Integer
  property :date,           DateTime
  has n, :advpayments
  belongs_to :project
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


######## CORPORATION

# busca parent y crea child con params

post '/:id' do
  User.get(params[:id]).corporations.create params['corporation']  
  redirect to('/')
end

# busca id y borra

delete '/corporation/:id' do
  Corporation.get(params[:id]).destroy
  redirect to('/')
end

# busca id y modifica

put '/corporation/:id' do
  corporation = Corporation.get params[:id]
  corporation.completed_at = corporation.completed_at.nil? ? Time.now : nil
  corporation.save
  redirect to('/')
end



######## CLIENT

# busca parent y crea child con params

post '/corporation/:id' do
  Corporation.get(params[:id]).clients.create! params['client'] 

  redirect to('/')
end

# busca id y borra

delete '/client/:id' do
  Client.get(params[:id]).destroy
  redirect to('/')
end

# busca id y modifica

put '/client/:id' do
  client = Client.get params[:id]
  client.completed_at = client.completed_at.nil? ? Time.now : nil
  client.save
  redirect to('/')
end




######## PROJECT

# busca parent y crea child con params

post '/client/:id' do

  client = Client.get(params[:id])
  project = client.projects.create! params['project']
  project.corporation_id = client[:corporation_id]
  project.save
  redirect to('/')
end

# busca id y borra

delete '/project/:id' do
  Project.get(params[:id]).destroy
  redirect to('/')
end

# busca id y modifica

put '/project/:id' do
  project = Project.get params[:id]
  project.completed_at = project.completed_at.nil? ? Time.now : nil
  project.save
  redirect to('/')
end


######## BUDGET

# busca parent y crea child con params

post '/project/:id' do

  Project.get(params[:id]).budgets.create! params['budget'] 

  redirect to('/')
end

# busca id y borra

delete '/budget/:id' do
  Budget.get(params[:id]).destroy
  redirect to('/')
end

# busca id y modifica

put '/budget/:id' do
  budget = Budget.get params[:id]
  budget.completed_at = budget.completed_at.nil? ? Time.now : nil
  budget.save
  redirect to('/')
end

######## ADVPAYMENT

# busca parent y crea child con params

post '/budget/:id' do

  budget = Budget.get(params[:id])
  advpayment = budget.advpayments.create! params['advpayment']
  advpayment.project_id = budget[:project_id]


  parent_class =  Project.get(budget[:project_id])

  advpayment.client_id = parent_class[:client_id]

  advpayment.save
  redirect to('/')
end

# busca id y borra

delete '/advpayment/:id' do
  Advpayment.get(params[:id]).destroy
  redirect to('/')
end

# busca id y modifica

put '/advpayment/:id' do
  advpayment = Advpayment.get params[:id]
  advpayment.completed_at = advpayment.completed_at.nil? ? Time.now : nil
  advpayment.save
  redirect to('/')
end
  





