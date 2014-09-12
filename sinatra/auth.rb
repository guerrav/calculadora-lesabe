require 'sinatra/base'
require 'sinatra/flash'


module Sinatra
	module Auth
		module Helpers
			def authorized?
				session[:admin]
			end

			def protected!
        		halt 401,slim(:unauthorized) unless authorized?
			end 

			def current_user
  				@current_user ||= User.get(session[:admin]) if session[:admin]
			end

			def client_any
		    	@current_user ||= User.get(session[:admin]) if session[:admin]
		    	if @current_user
		    		x = @current_user.corporations.clients.last()
		    	end 
			end

			def supplier_any

		    	@current_user ||= User.get(session[:admin]) if session[:admin]
		    	if @current_user
		    		x = @current_user.corporations.suppliers.last()
		    	end
			end

			def projects_any

		    	@current_user ||= User.get(session[:admin]) if session[:admin]
		    	if @current_user
		    		x = @current_user.corporations.clients.projects.last()
		    	end
			end

			def user_projects

		    	@current_user ||= User.get(session[:admin]) if session[:admin]
		    	if @current_user
		    		x = @current_user.corporations.clients.projects.all()
		    	end
			end


		end

	def self.registered(app)
		app.helpers Helpers 

		app.enable :sessions

		app.set :username => 'frank',
				:password => 'sinatra'

		app.get '/login' do 
			slim :login
		end

		app.get '/register' do 
			slim :login
		end

		app.post '/register' do
    		@user = env['omniauth.identity']
    		slim :login
 		end

		
      	
      	app.get '/logout' do
        	session[:admin] = nil
        	flash[:notice] = "You have now logged out"
        	redirect to('/')
		end 



 		app.get '/auth/:provider/callback' do


	      	auth = request.env["omniauth.auth"]
	      	authentication = Authentication.find_with_omniauth(auth)

	      	if authentication
	      		authentication.user_id == current_user
	      		flash[:notice] = "existe una auth ligada a user.id #{authentication.id} " 
	      		redirect to('/')

	      	else
	      		user = User.create!
	      		user.authentications.create!(uid: auth["uid"], provider: auth["provider"])
	      		user.save
	      		session[:admin] = user.id
	      		flash[:notice] = "lo logre  #{user.id} "
	      		redirect to('/index')
 
			end 
	    end


		app.post '/auth/:provider/callback' do
		  
		  auth = request.env["omniauth.auth"]


		  user = User.all.first(email: auth["info"]["email"])



			if user.corporations.last 
				session[:admin] = user.id
				redirect to('/corporation')
			end


		  if user
		    session[:admin] = user.id
		    flash[:notice] = "You are now logged in as #{user.email}" 
		    redirect to('/start')



		

		  else
		    user = User.new email: auth["info"]["email"]
		    user.save
		    session[:admin] = user.id
		    flash[:notice] = "no hay match entonces genera un usario " 
		    redirect to('/index')

		

		  end


		end
		 

		 
		app.get '/auth/failure' do
			flash[:notice] = "The username or password you entered are incorrect"
          	redirect to('/')
		end









	end
end
  register Auth
end