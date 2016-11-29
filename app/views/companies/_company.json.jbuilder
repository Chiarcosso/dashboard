json.extract! company, :id, :name, :vat_number, :ssn, :created_at, :updated_at
json.url company_url(company, format: :json)