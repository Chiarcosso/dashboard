class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :query_params, only: [:send_query]

  def queries
    @list = Query.where(:model_class => 'Vehicle').first.nil?? '' : Query.where(:model_class => 'Vehicle').first.query
    render 'admin/query'
  end

  def send_query

  end

  private

  def query_params
    case params.require(:model_class)
    when 'Vehicle'
      @query = %{SELECT Targa AS plate, f.RagioneSoc AS property, anno AS registrationDate,
              Marca AS manufacturer, Modello AS model, Telaio AS chassis, Km AS mileage,
              FROM Veicoli v
              INNER JOIN Fornitori f ON f.IDFornitore = v.IDFornitore
              INNER JOIN Tipo t ON t.IDTipo = v.IDTipo
            }
    end
  end

  def authorize_admin
    unless current_user.has_role? :admin
      redirect_to 'home/agenda'
    end
  end

end
