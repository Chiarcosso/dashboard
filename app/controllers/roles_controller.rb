class RolesController < ApplicationController
  # authorize!

  def create
    Role.create(create_params)
    # render :partial, 'layout/reload'
  end

  protected

  def create_params
    params.require(:role).permit(:name)
  end
end
