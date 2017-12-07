class FixManufacturers < ActiveRecord::Migration[5.0]
  def change
    rename_column :companies, :manufacturer, :vehicle_manufacturer unless column_exists? :companies, :vehicle_manufacturer
    add_column :companies, :item_manufacturer, :boolean, null: false, default: false, index: true unless column_exists? :companies, :item_manufacturer
    add_index :companies, :vehicle_manufacturer unless index_exists? :companies, :vehicle_manufacturer
    add_index :companies, :transporter unless index_exists? :companies, :transporter
    add_index :companies, :institution unless index_exists? :companies, :institution
    add_index :companies, :formation_institute unless index_exists? :companies, :formation_institute
    add_index :companies, :client unless index_exists? :companies, :client
    add_index :companies, :supplier unless index_exists? :companies, :supplier
    add_index :companies, :workshop unless index_exists? :companies, :workshop
    VehicleModel.all.each do |m|
      m.manufacturer.update(vehicle_manufacturer: true) unless m.manufacturer.nil?
      puts m.manufacturer.name unless m.manufacturer.nil?
    end
    Article.all.each do |a|
      a.manufacturer.update(item_manufacturer: true) unless a.manufacturer.nil?
      puts a.manufacturer.name unless a.manufacturer.nil?
    end
  end

end
