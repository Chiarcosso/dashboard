class AdministrationController < ApplicationController

  def totals
    render 'administration/totals'
  end

  def financial_inventory
    @articles = Article.order(:name)
    respond_to do |format|
      # format.html
      format.csv { send_data @articles.to_csv(col_sep: ";") }
      format.xls { send_data @articles.to_csv(col_sep: "\t") }
    end
  end

  def workshop_financial
    company = Company.find(params.require(:company_id).to_i)
    year = params.require(:year)

    respond_to do |format|
      # format.html
      format.csv { send_data @worksheets.to_worksheet_financial_csv({col_sep: ";"},year) }
      format.xls { send_data company.to_worksheet_financial_csv({col_sep: "\t"},year) }
    end
  end

end
