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
			slim :welcome
		end

		app.get '/register' do 
			slim :begin
		end

		app.post '/register' do
    		@user = env['omniauth.identity']
    		slim :begin
 		end

		
      	
      	app.get '/logout' do
        	session[:admin] = nil
        	redirect to('/')
		end 



 		app.get '/auth/:provider/callback' do


	      	
	      	auth = request.env["omniauth.auth"]
	      	authentication = Authentication.all.last(uid: auth["uid"], provider: auth["provider"])


	      	if authentication
	      		session[:admin] == authentication.user_id
	      		redirect to('/')

	      	elsif current_user
	      		user = current_user.authentications.create!(uid: auth["uid"], provider: auth["provider"])
	      		user.save
	      		redirect to('/')


	      	else
	      		user = User.create!(name: auth["info"]["name"])
	      		corporation = Corporation.create!(user_id: user["id"]) 
			    corporation.save
	      		user.authentications.create!(uid: auth["uid"], provider: auth["provider"])
	      		
	      		if user.save
	      			session[:admin] = user.id
	      			redirect to('/')
	      		else
	      			session[:omniauth] = auth.except('extra')
	      			redirect to('/authentication')
	      		end


	      		
	      		
	      		
 
			end 

		
	    end


		app.post '/auth/:provider/callback' do
		  
			auth = request.env["omniauth.auth"]
			user = User.all.first(email: auth["info"]["email"])

			if user.corporations.last 
				session[:admin] = user.id
				redirect to('/')
			end

			if user
				corporation = Corporation.create!(user_id: user["id"]) 
			    corporation.save
			    session[:admin] = user.id
			    redirect to('/')

			else
			    user = User.new email: auth["info"]["email"]
			    user.save
			    
			    session[:admin] = user.id
			    redirect to('/')		

			end


		end
		 
		 
		app.get '/auth/failure' do
			flash[:notice] = "El usario o contraseña son incorrectos"
          	redirect to('/')
		end


	end
end
  register Auth
end