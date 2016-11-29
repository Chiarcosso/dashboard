json.extract! transport_document, :id, :number, :date, :reason, :created_at, :updated_at
json.url transport_document_url(transport_document, format: :json)