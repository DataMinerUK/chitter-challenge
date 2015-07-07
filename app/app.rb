require 'sinatra'
require 'sinatra/base'
require 'sinatra/flash'
require './app/data_mapper_setup'

class Chitter < Sinatra::Base
  enable :sessions
  register Sinatra::Flash

  get '/' do
    if current_user
      redirect '/sessions/new'
    else
      @all_users = User.all.map{ |user| user.username } # this could be a method on User
      erb :'users/sign_up'
    end
  end

  get '/:username' do # never define a route like this... bad things ensue because of the way chrome gets favicons >_<
    @user = User.first(username: params[:username])
    if @user
      get_users_peeps_and_replies
      erb :'sessions/peeps'
    else
      erb :'users/not_found'
    end
  end

  post '/:username' do # post '/peeps/:peep_id/replies'
    @user = User.first(username: params[:username])
    if params[:reply] == ''
      flash.now[:errors] = "Cannot post a blank peep!"
    else
      peep = Peep.create(text: params[:reply], time_stamp: Time.now, user_id: current_user.id, reply: true, replied_id: params[:peep_id], replied_to: @user.username)
      current_user.peeps << peep
    end
    get_users_peeps_and_replies
    erb :'sessions/peeps'
  end

  post '/users/new' do # not a conventional route.. should be post '/users'
    @user = User.new(username: params[:username], name: params[:name], email: params[:email], password: params[:password])
    if @user.save
      session[:user_id] = @user.id
      erb :'users/new'
    else
      flash[:errors] = @user.errors.full_messages
      redirect '/'
    end
  end

  post '/sessions/new' do # 'post /sessions'
    if User.first(username: params[:username])
      @user = User.authenticate(username: params[:username], password: params[:password])
      if @user
        session[:user_id] = @user.id unless session[:user_id]
        get_users_peeps_and_replies
        erb :'sessions/peeps'
      else
        flash[:errors] = ['Incorrect password']
        redirect '/'
      end
    else
      flash[:errors] = ['No username exists, try signing up']
      redirect '/'
    end
  end

  get '/sessions/new' do
    @user = current_user
    get_users_peeps_and_replies
    erb :'sessions/peeps'
  end

  post '/sessions/end' do # shouldn't this be delete /session?
    session.clear
    erb :'sessions/goodbye'
  end

  post '/peeps/new' do # '/peeps'
    @user = current_user
    if params[:peep] == ''
      flash.now[:errors] = "Cannot post a blank peep!"
    else
      current_user.peeps.create(text: params[:peep], time_stamp: Time.now)
    end
    get_users_peeps_and_replies
    erb :'sessions/peeps'
  end

  helpers do

    def current_user
      User.get(session[:user_id])
    end

    def get_users_peeps_and_replies # this could be a method on Peep
      @peeps = @user.peeps.all(:order => :time_stamp.desc )
      all_users_peep_ids = @peeps.map{ |peep| peep.id }
      replies = Peep.all(reply: true)
      @users_replies = replies.select{ |peep| all_users_peep_ids.include?(peep.replied_id) }
    end

  end

end
