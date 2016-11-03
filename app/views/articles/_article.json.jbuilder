json.extract! article, :id, :barcode, :manufacturerCode, :name, :description, :containedAmount, :minimalReserve, :postionCode, :created_at, :updated_at
json.url article_url(article, format: :json)