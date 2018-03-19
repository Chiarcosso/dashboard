class HomeController < ApplicationController

  def dashboard
    if (current_user.has_role? 'officina') || (current_user.has_role? 'amministratore officina')
      @search = {:opened => true, :closed => false, :plate => nil, :number => nil, :date_since => nil, :date_to => nil, :mechanic => nil}
      view =  "workshop/index"
    else
      view = "_agenda"
    end
    render view
  end

end
