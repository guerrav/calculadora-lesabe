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
		end

	def self.registered(app)
		app.helpers Helpers 

		app.enable :sessions

		app.set :username => 'frank',
				:password => 'sinatra'

		app.get '/login' do 
			slim :login
		end

		
      	
      	app.get '/logout' do
        	session[:admin] = nil
        	flash[:notice] = "You have now logged out"
        	redirect to('/')
		end 




		app.post '/auth/:provider/callback' do
		  
		  auth = request.env["omniauth.auth"]


		  user = User.all.first(email: auth["info"]["email"])


		# CHECA EL CALLBACK, SI EXISTE EL USUARIO PARA COMO TRUE Y LO VERIFICA 

		  if user
		    session[:admin] = user.id
		    flash[:notice] = "You are now logged in as #{user.email}" 
		    redirect to('/')

		# CHECA EL CALLBACK, NO EXISTE USER LO CREA Y INGRESA LA INFO DEL HASH EN EMAIL

		  else
		    user = User.new email: auth["info"]["email"]
		    user.save
		    session[:admin] = user.id
		    flash[:notice] = "no hay match entonces genera un usario " 
		    redirect to('/')
		  end

		end
		 

		 
		app.get '/auth/failure' do
			flash[:notice] = "The username or password you entered are incorrect"
          	redirect to('/login')
		end









	end
end
  register Auth
end