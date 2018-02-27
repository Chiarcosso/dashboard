class WorksheetsController < ApplicationController

  def index
    render 'workshop/index'
  end

  def set_hours
    Worksheet.find(set_hours_params[:id]).update(:hours => set_hours_params[:hours])
  end



  private

  def set_hours_params
    params.require(:worksheet).permit(:id,:hours)
  end

end
