class CreateGeneralParameters < ActiveRecord::Migration[5.0]
  def change
    unless table_exists? :general_parameters
      create_table :general_parameters do |t|
        t.string :parameter, null: false
        t.float :value, null: false

        t.timestamps
      end
      add_index :general_parameters, :parameter, unique: true
    end

    GeneralParameter.create(parameter: 'magazzino_limite_superiore_percentuale_prezzo', value: 110)
    GeneralParameter.create(parameter: 'magazzino_limite_inferiore_percentuale_prezzo', value: 90)
    GeneralParameter.create(parameter: 'magazzino_limite_superiore_percentuale_sconto', value: 110)
    GeneralParameter.create(parameter: 'magazzino_limite_inferiore_percentuale_sconto', value: 90)
  end
end
