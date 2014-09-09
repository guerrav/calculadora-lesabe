require 'sinatra'
require 'sinatra/flash'
require 'sinatra/reloader' if development?
require 'slim'
require 'sass'
require 'data_mapper'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'omniauth-identity'
require 'omniauth-twitter'
require 'dm-ar-finders'
require './sinatra/auth'
require 'sinatra/assetpack'
require 'sinatra/support/numeric'


#INICIALIZERS


register Sinatra::Numeric

configure :development do
    DataMapper.auto_upgrade!
end



configure do 

  set :default_currency_unit, '$'
  set :default_currency_precision, 2
  set :default_currency_separator, ','
end

assets do
  serve '/js', from: 'js'
  serve '/bower_components', from: 'bower_components'

  js :modernizr, [
    '/bower_components/modernizr/modernizr.js',
  ]

  js :libs, [
    '/bower_components/jquery/dist/jquery.js',
    '/bower_components/foundation/js/foundation.js'
  ]

  js :application, [
    '/js/app.js'
  ]

  js_compression :jsmin
end



#omniauth initializer

use Rack::Session::Pool
use OmniAuth::Builder do
  #IDENTITY
  provider :identity, :fields => [:email, :username], model: User, on_failed_registration: lambda { |env|
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
  property :upDated_at,   DateTime

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
  property :name,           String
  property :description,    String
  property :status,         String
  property :completed_at,   Date
  has n, :projects
  has n, :clients
  has n, :suppliers
  belongs_to :user
end

class Client
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String, required: true
  has n, :advpayments
  has n, :projects
  belongs_to :corporation

end

class Supplier
  include DataMapper::Resource
  property :id,           Serial
  property :name,         String, required: true
  has n, :payments
  has n, :quotes

  belongs_to :corporation

end

class Project
  include DataMapper::Resource
  property :id,             Serial
  property :name,           String, required: true
  property :description,    String
  property :client_name,    String
  property :status,         String
  property :completed_at,   DateTime
  has n, :budgets 
  has n, :costs
  belongs_to :client
  belongs_to :corporation
end

class Budget
  include DataMapper::Resource
  property :id,             Serial
  property :amount,         Integer, default: 0
  property :created_at,     DateTime
  has n, :advpayments
  belongs_to :project
end
 


class Advpayment
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer, default: 0
  property :client_name,  String, required: true
  property :created_at,   DateTime
  belongs_to :client
  belongs_to :project

end

class Cost
  include DataMapper::Resource
  property :id,             Serial
  property :amount,         Integer, default: 0
  property :created_at,     DateTime

  has n, :quotes
  has n, :purchases
  belongs_to :project
end


class Purchase
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer, default: 0
  property :description,  String, required: true
  property :created_at,   DateTime
  belongs_to :cost

end

class Quote
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer, default: 0
  property :supplier_name,  String, required: true
  property :created_at,     DateTime
  has n, :payments
  belongs_to :supplier
  belongs_to :cost

end

class Payment
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer, default: 0
  property :supplier_name,  String
  property :created_at,         DateTime
  belongs_to :supplier
  belongs_to :quote
  
end



DataMapper.finalize


#HOME PONE A TODOS LOS USUARIOS 

get '/' do
  protected!
  @corporation = current_user.corporations.last() if current_user.corporations
  @projects = @corporation.clients.projects.all() if @corporation

  slim :projects
end

get '/corporation' do
  protected!
  @user = current_user
  @corporation = @user.corporations.last()
  slim :corporation_info
end



get '/projects' do
  protected!
  @corporation = current_user.corporations.last()
  @projects = @corporation.clients.projects.all()
  



  slim :projects
end


get '/welcome' do  

  slim :welcome
end

get '/index' do  
  protected!
  slim :index
end









######## CORPORATION

# busca parent y crea child con params

post '/:id' do
  User.get(params[:id]).corporations.create params['corporation']  
  redirect back
end

# busca id y borra

delete '/corporation/:id' do
  Corporation.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/corporation/:id' do
  corporation = Corporation.get params[:id]
  corporation.completed_at = corporation.completed_at.nil? ? Time.now : nil
  corporation.save
  redirect back
end





















######## CLIENT

# busca parent y crea child con params

post '/corporation/:id' do
  client = Corporation.get(params[:id]).clients.create! params['client'] 
  client.save

  redirect back
end

# busca id y borra

delete '/client/:id' do
  Client.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/client/:id' do
  client = Client.get params[:id]
  client.completed_at = client.completed_at.nil? ? Time.now : nil
  client.save
  redirect back
end




######## SUPPLIER

# busca parent y crea child con params

post '/suppliers/:id' do
  Corporation.get(params[:id]).suppliers.create! params['supplier'] 

  redirect back
end

# busca id y borra

delete '/supplier/:id' do
  Supplier.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/supplier/:id' do
  supplier = Supplier.get params[:id]
  supplier.completed_at = supplier.completed_at.nil? ? Time.now : nil
  supplier.save
  redirect back
end
















######## PROJECT

# busca parent y crea child con params

post '/client/:id' do

  client = Client.get(params[:id])
  project = client.projects.create! params['project']
  project.corporation_id = client[:corporation_id]
  project.save
  redirect back
end

post '/clientx/:id' do

  corporation = Corporation.get(params[:id])

  project = corporation.clients.projects.create! params['project']
  project.save


  client = Client.all.last(name: project["client_name"])

  project.client_id = client[:id]
  project.corporation_id = corporation[:id]
  project.save
  redirect back
end


 




# busca id y borra

delete '/project/:id' do
  Project.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/project/:id' do
  project = Project.get params[:id]
  project.completed_at = project.completed_at.nil? ? Time.now : nil
  project.save
  redirect back
end
















######## BUDGET

# busca parent y crea child con params

post '/project/:id' do

  budget = Project.get(params[:id]).budgets.create! params['budget']
  cost = Project.get(params[:id]).costs.create!

  budget.save
  cost.save

  redirect back
end

# busca id y borra

delete '/budget/:id' do
  Budget.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/budget/:id' do
  budget = Budget.get params[:id]
  budget.completed_at = budget.completed_at.nil? ? Time.now : nil
  budget.save
  redirect back
end




######## COST


# busca id y borra

delete '/cost/:id' do
  Cost.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/cost/:id' do
  cost = Cost.get params[:id]
  cost.completed_at = cost.completed_at.nil? ? Time.now : nil
  cost.save
  redirect back
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
  redirect back
end

# busca id y borra

delete '/advpayment/:id' do
  Advpayment.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/advpayment/:id' do
  advpayment = Advpayment.get params[:id]
  advpayment.completed_at = advpayment.completed_at.nil? ? Time.now : nil
  advpayment.save
  redirect back
end




















######## PURCHASE

post '/cost/:id' do
  

  purchase = Cost.get(params[:id]).purchases.create! params['purchase'] 
  purchase.save

  

  redirect back
end

# busca id y borra

delete '/purchase/:id' do
  Purchase.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/purchase/:id' do
  purchase = Purchase.get params[:id]
  purchase.completed_at = purchase.completed_at.nil? ? Time.now : nil
  purchase.save
  redirect back
end









######## QUOTE

post '/quote/:id' do

  
  

  quote = Cost.get(params[:id]).quotes.create! params['quote'] 

  supplier = Supplier.all.first(name: quote["supplier_name"])

  quote.supplier_id = supplier[:id]

  quote.save

  redirect back
end

# busca id y borra

delete '/quote/:id' do
  Quote.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/purchase/:id' do
  quote = Quote.get params[:id]
  quote.completed_at = quote.completed_at.nil? ? Time.now : nil
  quote.save
  redirect back
end
    




######## PAYMENT

post '/payment/:id' do
  


  payment = Quote.get(params[:id]).payments.create! params['payment'] 

  supplier = Supplier.all.first(name: payment["supplier_name"])

  payment.supplier_id = supplier[:id]



  

  payment.save


  

  redirect back
end

# busca id y borra

delete '/payment/:id' do
  Payment.get(params[:id]).destroy
  redirect back
end

# busca id y modifica

put '/payment/:id' do
  payment = Payment.get params[:id]
  payment.completed_at = payment.completed_at.nil? ? Time.now : nil
  payment.save
  redirect back
end
    
