class CreateVehicleProperties < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :vehicle_properties
      create_table :vehicle_properties do |t|
        t.references :vehicle, foreign_key: true, null: false, index:true
        t.references :owner, polymorphic: true, null: false, index: true
        t.date :date_since
        t.date :date_to

        t.timestamps
      end
    end
    # Vehicle.all.each do |v|
    #   VehicleProperty.create(vehicle: v, owner: v.property, date_since: v.registration_date) unless v.has_property?(v.property) or v.property.nil?
    # end

  end

end
