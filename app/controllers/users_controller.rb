class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize
  load_and_authorize_resource
  before_action :get_user, only: [:edit, :delete, :show, :add_role, :rem_role]
  before_action :create_params, only: [:create]

  def new
    @user = User.new
    # @user.person = Person.new
    render 'user/modify'
  end

  def index

    @users = User.all
    render 'user/index'

  end

  def edit
    render 'user/modify'
  end

  def show
  end

  def create
    p = create_params
    p[:person_id] = 0
    @user = User.create! p
    redirect_to edit_user_admin_path(@user)
  end

  def modify
    @user.update(params[:user])
    redirect_to users_path
  end

  def delete
    @user.destroy
    redirect_to users_admin_path
  end

  def add_role
    role = Role.find(params[:role])
    @user.add_role(role.name.to_sym)
    redirect_back fallback_location: edit_user_admin_url(@user)
  end

  def rem_role
    role = Role.find(params[:role])
    @user.remove_role(role.name.to_sym)
    redirect_back fallback_location: edit_user_admin_url(@user)
  end

  private

  def authorize
    if (!current_user.has_role? :admin) && (!current_user.has_role? :amministratore_utenti)
      # render text:"No access for you!"
      render "home/_agenda"
    else
      [:admin, :base, "amministratore utenti", :magazzino].each do |role|
        Role.find_or_create_by({ name: role })
      end
    end
  end

  def get_user
    @user = User.find(params[:id])
    @user.person ||= Person.new
    @person = @user.person
  end

  def create_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation, :person_id)
  end

  def checkout_params
    params.require(:user).permit(:user,:id,:role)
  end

end
