class HomeController < ApplicationController

  def dashboard
    # if (current_user.has_role? 'presenze e orari')
    #   redirect_to '/presence/manage/'
    #   return 0
    # elsif (current_user.has_role? 'odl aperti') || (current_user.has_role? 'amministratore officina')
    #   # @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => nil, :date_to => nil, :mechanic => nil}
    #   # view =  "workshop/index"
    #   redirect_to '/worksheets/'
    #   return 0
    #
    #
    # elsif (current_user.has_role? 'lavaggio') || (current_user.has_role? 'checkup point')
    #   redirect_to '/carwash/checks/'
    #   return 0
    # elsif (current_user.has_role? 'magazzino')
    #   redirect_to '/storage/'
    #   return 0
    # else
    #   view = "_agenda"
    # end
    
    if(current_user.homepage == '/')
      render "_agenda"
    else
      redirect_to current_user.homepage
    end
  end

end
