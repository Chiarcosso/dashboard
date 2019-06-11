class RolesController < ApplicationController
  before_action :authenticate_user!
  # authorize!

  def create
    Role.create(create_params)
    # render :js, partial: 'user/partials/reload_roles'
    redirect_to edit_user_admin_url(@user)
  end

  protected

  def create_params
    @user = User.find(params.require(:user).to_i)
    params.require(:role).permit(:name)
  end
end

private

def authorize
  if (!current_user.has_role? :admin) && (!current_user.has_role? :amministratore_utenti)
    # render text:"No access for you!"
    render "home/_agenda"
  else
    roles = [:base, "utenti", 'magazzino', "ditte"]
    if current_user.has_role? :admin
      roles << :admin
    end
    roles.each do |role|
      Role.find_or_create_by({ name: role })
    end
  end
end
