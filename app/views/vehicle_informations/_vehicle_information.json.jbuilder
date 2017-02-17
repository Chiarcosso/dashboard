json.extract! vehicle_information, :id, :vehicle_id, :information_type, :information, :date, :created_at, :updated_at
json.url vehicle_information_url(vehicle_information, format: :json)