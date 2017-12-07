class CreateLanguages < ActiveRecord::Migration[5.0]
  def change
    create_table :languages do |t|
      t.string :name

      t.timestamps
    end

    Language.create(name: 'Italiano')
    Language.create(name: 'Tedesco')
    Language.create(name: 'Inglese')
    Language.create(name: 'Croato')
    Language.create(name: 'Sloveno')
    Language.create(name: 'Francese')
    Language.create(name: 'Rumeno')
    Language.create(name: 'Albanese')
    Language.create(name: 'Ungherese')
    Language.create(name: 'Russo')
    GeoState.create(name: 'Italia', code: 'IT', language: Language.find_by_name('Italiano'))
    GeoState.create(name: 'Germania', code: 'DE', language: Language.find_by_name('Tedesco'))
    GeoState.create(name: 'Austria', code: 'AT', language: Language.find_by_name('Tedesco'))
  end
end
