require 'sinatra'
require 'sinatra/flash'
require 'slim'
require 'sass'
require 'data_mapper'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'omniauth-identity'
require 'omniauth-twitter'
require './sinatra/auth'
require 'sinatra/assetpack'
require 'sinatra/support/numeric'





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







#OMNIAUTH IDENTITY

use Rack::Session::Pool
use OmniAuth::Builder do
  #IDENTITY
  provider :identity, :fields => [:email, :name, :lastname], model: User, on_failed_registration: lambda { |env|
      status, headers, body = call env.merge("PATH_INFO" => '/register')
    }
    OmniAuth.config.on_failure = Proc.new { |env|
      OmniAuth::FailureEndpoint.new(env).redirect_to_failure
    }

    #TWITTER
  provider :twitter, 'dpGgrLpsjZl94CwwdykqoABuU', 'YJlE5EN36opAZRKgsx4lbHToaoz0h3RjPAmzEDHLrfUFGZyAjW'

end








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
  property :password_digest,     Text 
  property :name,         String
  property :lastname,     String
  property :created_at,   DateTime

  attr_accessor :password_confirmation

  validates_presence_of :email, :name, :lastname
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
  property :index,          Integer, default: 1
  property :description,    String
  property :client_name,    String
  property :status,         String, default: 0
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
  property :client_name,  String
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
  has n, :works
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

class Work
  include DataMapper::Resource
  property :id,           Serial
  property :amount,       Integer, default: 0
  property :description,  String
  property :created_at,   DateTime
  belongs_to :cost
end











configure do
  DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")
  DataMapper.finalize
  DataMapper.auto_upgrade!
end










get '/' do
  protected!
  @corporation = current_user.corporations.last() if current_user.corporations
  @projects = @corporation.clients.projects.all() if @corporation
  slim :summary
end


get '/welcome' do  
  slim :welcome
end

get '/start' do  
  protected!
  slim :index
end


get '/begin' do  
  slim :begin
end












get '/corporation' do
  protected!
  @user = current_user
  @corporation = @user.corporations.last()
  slim :corporation_info
end


get '/project/:index' do
  protected!
  @user = current_user
  @corporation = @user.corporations.last() 
  if params[:id] == 1
    @user.corporations.last() 
    
  else
    @project = Project.all.last(index: params['index'], corporation_id: @corporation['id']) 
  end

  slim :project
end


get '/projects' do
  protected!
  @corporation = current_user.corporations.last() if current_user.corporations
  slim :projects
end















######## CORPORATION



post '/:id' do
  corporation = User.get(params[:id]).corporations.create params['corporation'] 
  corporation.completed_at = corporation.completed_at.nil? ? Time.now : nil
  corporation.save
  redirect back
end

# DELETE

delete '/corporation/:id' do
  Corporation.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/corporation/:id' do
  corporation = Corporation.get params[:id]
  corporation.update(params[:corporation])  
end




######## CLIENT


post '/corporation/:id' do
  client = Corporation.get(params[:id]).clients.create params['client'] 
  client.save
  redirect back
end

# DELETE

delete '/client/:id' do
  Client.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/client/:id' do
  client = Client.get params[:id]
  client.update(params[:client])  
end


######## SUPPLIER


post '/suppliers/:id' do
  supplier = Corporation.get(params[:id]).suppliers.create params['supplier'] 
  supplier.save
  redirect back
end

# DELETE

delete '/supplier/:id' do
  Supplier.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/supplier/:id' do
  supplier = Supplier.get params[:id]
  supplier.update(params[:supplier])  
end





######## PROJECT



post '/client/:id' do
  client = Client.get(params[:id])
  project = client.projects.create! params['project']
  project.corporation_id = client[:corporation_id]
  project.completed_at = project.completed_at.nil? ? Time.now : nil
  project.save
  redirect back
end

post '/clientx/:id' do
  project = Corporation.get(params[:id]).projects.create! params['project'] 
  client = Client.all.first(name: project["client_name"])
  project.client_id = client[:id]
  project.completed_at = project.completed_at.nil? ? Time.now : nil
  project.save
  redirect back
end

 
post '/status0/:id' do
  project = Project.get(params[:id])
  project.status = "1"
  project.save
  redirect back
end


post '/status1/:id' do
  project = Project.get(params[:id])
  project.status = "0"
  project.save
  redirect back
end

  

# DELETE

delete '/project/:id' do
  project = Project.get(params[:id])
  
  Budget.all(project_id: project["id"]).advpayments.destroy
  Budget.all(project_id: project["id"]).destroy
  Project.last(id: project["id"]).costs.quotes.payments.destroy
  Project.last(id: project["id"]).costs.quotes.destroy
  
  Project.last(id: project["id"]).costs.purchases.destroy
  Project.last(id: project["id"]).costs.works.destroy
  Cost.all(project_id: project["id"]).destroy
  project.destroy!
  flash[:notice] = "Proyecto borrado"  
  
  redirect to ('/projects')
end

# UPDATE

put '/project/:id' do
  project = Project.get params[:id]
  project.update(params[:project])
  redirect back
end





######## BUDGET


post '/project/:id' do
  budget = Project.get(params[:id]).budgets.create! params['budget']
  cost = Project.get(params[:id]).costs.create!
  budget.created_at = budget.created_at.nil? ? Time.now : nil
  budget.save
  cost.created_at = cost.created_at.nil? ? Time.now : nil
  cost.save
  redirect back
end

# DELETE

delete '/budget/:id' do
  Budget.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/budget/:id' do
  budget = Budget.get params[:id]
  budget.completed_at = budget.completed_at.nil? ? Time.now : nil
  budget.save
  redirect back
end



######## COST


# DELETE

delete '/cost/:id' do
  Cost.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/cost/:id' do
  cost = Cost.get params[:id]
  cost.completed_at = cost.completed_at.nil? ? Time.now : nil
  cost.save
  redirect back
end





######## ADVPAYMENT


post '/budget/:id' do
  budget = Budget.get(params[:id])
  advpayment = budget.advpayments.create! params['advpayment']
  advpayment.project_id = budget[:project_id]
  parent_class =  Project.get(budget[:project_id])
  advpayment.client_id = parent_class[:client_id]
  advpayment.save
  redirect back

end

# DELETE

delete '/advpayment/:id' do
  Advpayment.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/advpayment/:id' do
  advpayment = Advpayment.get params[:id]
  advpayment.completed_at = advpayment.completed_at.nil? ? Time.now : nil
  advpayment.save
  redirect back
end





######## PURCHASE

post '/cost/:id' do
  purchase = Cost.get(params[:id]).purchases.create! params['purchase'] 
  purchase.created_at = purchase.created_at.nil? ? Time.now : nil
  purchase.save
  redirect back

end

# DELETE

delete '/purchase/:id' do
  Purchase.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/purchase/:id' do
  purchase = Purchase.get params[:id]
  purchase.created_at = Time.now 
  purchase.save
  redirect back
end


######## WORKS

post '/work/:id' do
  work = Cost.get(params[:id]).works.create! params['work'] 
  work.created_at = work.created_at.nil? ? Time.now : nil
  work.save
  redirect back

end

# DELETE

delete '/work/:id' do
  Work.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/work/:id' do
  work = Work.get params[:id]
  work.created_at = Time.now 
  work.save
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

# DELETE

delete '/quote/:id' do
  Quote.get(params[:id]).destroy
  redirect back
end

# UPDATE

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
  payment.created_at = payment.created_at.nil? ? Time.now : nil
  payment.save
  redirect back

end

# DELETE

delete '/payment/:id' do
  Payment.get(params[:id]).destroy
  redirect back
end

# UPDATE

put '/payment/:id' do
  payment = Payment.get params[:id]
  payment.completed_at = payment.completed_at.nil? ? Time.now : nil
  payment.save
  redirect back
end
    
