class UsersController < ApplicationController
  before_action :authenticate_user!
  # before_action :authorize!
  load_and_authorize_resource
  before_action :get_user, only: [:update,:delete, :show, :add_role, :rem_role]
  before_action :create_params, only: [:create]

  def new
    @role = Role.new
    @user = User.new
    # @user.person = Person.new
    render 'user/modify'
  end

  def index

    @users = User.all.sort_by { |u| u.person.nil?? u.email : u.person.surname }
    render 'user/index'

  end

  def edit
    @role = Role.new
    render 'user/modify'
  end

  def show
  end

  def create
    @user = User.create! create_params
    redirect_to edit_user_admin_path(@user)
  end

  def update
    create_params.each do |k,v|
      @user.update_attribute(k,v)
    end

    @user.errors.full_messages
    redirect_to users_admin_path
  end

  def delete
    # @user.destroy
    @user.update(active: !@user.active)
    redirect_to users_admin_path
  end

  def add_role
    role = Role.find(params[:role])
    @user.add_role(role.name.to_sym)
    redirect_back fallback_location: edit_user_admin_url(@user)
  end

  def rem_role
    role = Role.find(params[:role])
    # @user.remove_role(role.name.to_sym)
    @user.roles.delete(role)
    redirect_back fallback_location: edit_user_admin_url(@user)
  end

  private

  def authorize
    if (!current_user.has_role? :admin) && (!current_user.has_role? 'utenti')
      # render text:"No access for you!"
      if (current_user.has_role? 'officina') || (current_user.has_role? 'amministratore officina')
        render "workshop/index"
      end
      render "home/_agenda"
    else
      roles = [:base, "utenti", :magazzino, "ditte"]
      if current_user.has_role? :admin
        roles << :admin
      end
      roles.each do |role|
        Role.find_or_create_by({ name: role })
      end
    end
  end

  def get_user
    @user = User.find(params[:id])
    # @user.person ||= Person.new
    # @person = @user.person
  end

  def create_params
    p = params.require(:user).permit(:username, :email, :password, :password_confirmation, :person)
    unless p[:person].nil? || p[:person] == 0 || p[:person] == ''
      p[:person] = Person.find(p[:person].to_i)
    else
      p[:person] = nil
    end
    p
  end

  def checkout_params
    params.require(:user).permit(:user,:id,:role)
  end

end
