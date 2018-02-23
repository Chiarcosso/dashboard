class HomeController < ApplicationController

  def dashboard
    if (current_user.has_role? 'officina') || (current_user.has_role? 'amministratore officina')
      view =  "workshop/index"
    else
      view = "_agenda"
    end
    render view
  end

end
