json.extract! vehicle, :id, :references, :dismissed, :registration_date, :initial_serial, :mileage, :created_at, :updated_at
json.url vehicle_url(vehicle, format: :json)