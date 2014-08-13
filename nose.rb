

## tutorial de darren omniauth con twitter
 
get '/public' do
  "This is the public page - everybody is welcome!"
end
 
get '/private' do
  halt(401,'Not Authorized') unless admin?
  "This is the private page - members only"
end
 

 
get '/logout' do
  session[:admin] = nil
  "You are now logged out"
end



get '/auth/:provider/callback' do

  user = User.from_omniauth(env["omniauth.auth"])
  session[:admin] = user.id
  
end

get '/auth/failure' do
  params[:message]
end

## --------------------------------------------------------------



#


#SESSIONS CONTROLLER 

post '/auth/:provider/callback' do
  omniauth = request.env['omniauth.auth']
end




post '/new/identity' do 
  User.create params['identity']
  redirect to('/')
end



post '/auth/:provider/callback' do
  omniauth = request.env['omniauth.auth']
  user = User.get({:email omniauth['email']}, {:password omniauth['password']}) || User.create_with_omniauth(auth)
  session[:user_id] = user.id
  flash[:notice] = "Signed In" 
  redirect to('/')


end

post '/signout' do 
  session[:user_id] = nil
  flash[:notice] = "Signed out" 
  redirect to('/')
end 




  if omniauth["info"]["email"] == User.email && omniauth["info"]["password"] == User.password 
    session[:admin] = true
    flash[:notice] = "login  ! ."
  
  else
    flash[:notice] = "Hi ! You've signed up."
  end




if user 
    flash[:notice] = "Welcome back #{user.email}! You have already signed up."
  else

    user = User.new :email => omniauth["info"]["email"]
    user.save

    flash[:notice] = "Hi #{user.email}! You've signed up."
  end





post '/auth/identity/callback' do
  omniauth = request.env['omniauth.auth']

#  user = Identity.get(omniauth['email'])
  authorization = Identity.get(omniauth['email'])

#
  if authorization

    flash[:notice] = "Hi #{@authorization.user.email}! You've signed up."
  else
    
    user = User.new :email => omniauth["info"]["email"]
    user.save
    flash[:notice] = "Hi #{user.email}! You've signed up."
  end






  

#  session[:user_id] = user.id
  
  #redirect to('/')

