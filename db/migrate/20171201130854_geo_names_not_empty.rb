class GeoNamesNotEmpty < ActiveRecord::Migration[5.0]
  def change
    execute "ALTER TABLE languages ADD CONSTRAINT check_name_not_empty CHECK ( name <> '' )"
    execute "ALTER TABLE geo_states ADD CONSTRAINT check_name_not_empty CHECK ( name <> '' )"
    execute "ALTER TABLE geo_states ADD CONSTRAINT check_name_not_empty CHECK ( code <> '' )"
  end
end
