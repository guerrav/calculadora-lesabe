class Warden 

  Sinatra::Application

   get "/" do
    slim :index
  end 
 
  get "/protected_pages" do
    check_authentication
    slim :admin_only_page
  end
  
  get "/login" do
    slim :login
  end
 
  post "/session" do
    warden_handler.authenticate!
    if warden_handler.authenticated?
      redirect "/users/#{warden_handler.user.id}" 
    else
      redirect "/"
    end
  end
 
  get "/logout" do
    warden_handler.logout
    redirect '/login'
  end
 
  post "/unauthenticated" do
    redirect "/"
  end
use Rack::Session::Cookie
use Warden::Manager do |manager|
  manager.default_strategies :password
  manager.failure_app = Warden
  manager.serialize_into_session {|user| user.id}
  manager.serialize_from_session {|id| Datastore.for(:user).find_by_id(id)}
end
 
Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end
Warden::Strategies.add(:password) do
  def valid?
    params["email"] || params["password"]
  end
 
  def authenticate!
    user = Datastore.for(:user).find_by_email(params["email"])
    if user && user.authenticate(params["password"])
      success!(user)
    else
      fail!("Could not log in")
    end
  end


end

 def warden_handler
    env['warden']
  end
 
  def check_authentication
    unless warden_handler.authenticated?
      redirect '/login'
    end
  end
 
  def current_user
    warden_handler.user
  end
end