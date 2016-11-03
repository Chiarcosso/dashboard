class StorageController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize

  def home
    render 'storage/index'
  end

  def authorize
    if (!current_user.has_role? :admin) && (!current_user.has_role? :magazzino)
      # render text:"No access for you!"
      render "home/_agenda"
    end
  end
end
