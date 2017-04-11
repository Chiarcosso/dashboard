class StorageController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize

  autocomplete :company, :name


  def home
    @partial = 'storage/reception'
    render 'storage/index'
  end

  def reception
    @partial = 'storage/reception'
    render 'storage/index'
  end

  def output
    @partial = 'storage/output_initial'
    render 'storage/index'
  end

  def management
    @filteredArticles = Article.filter('')
    @partial = 'storage/manage'
    render 'storage/index'
  end

  def authorize
    if (!current_user.has_role? :admin) && (!current_user.has_role? :magazzino)
      # render text:"No access for you!"
      render "home/_agenda"
    end
  end
end
