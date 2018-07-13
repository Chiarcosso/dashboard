class CreateSensors < ActiveRecord::Migration[5.0]
  def change

    drop_table :presence_timestamps if table_exists? :presence_timestamps
    drop_table :sensors if table_exists? :sensors

    create_table :sensors do |t|
      t.integer :number
      t.string :name
      t.boolean :presence_relevant

      t.timestamps
    end
    Sensor.create(number: 0, name: 'Ingresso pedonale 1', presence_relevant: false)
    Sensor.create(number: 1, name: 'Ufficio 1° piano', presence_relevant: false)
    Sensor.create(number: 2, name: 'Corridoio mensa', presence_relevant: false)
    Sensor.create(number: 3, name: 'Ingresso seminterrato', presence_relevant: false)
    Sensor.create(number: 4, name: 'Presenza lavaggio', presence_relevant: true)
    Sensor.create(number: 5, name: 'Sensore 5', presence_relevant: false)
    Sensor.create(number: 6, name: 'Spogliatoi', presence_relevant: false)
    Sensor.create(number: 7, name: 'Ufficio personale', presence_relevant: false)
    Sensor.create(number: 8, name: 'Corridoio bagni', presence_relevant: false)
    Sensor.create(number: 9, name: 'Corridoio archivio', presence_relevant: false)
    Sensor.create(number: 10, name: 'Ingresso pedonale 2', presence_relevant: false)
    Sensor.create(number: 11, name: 'Ingresso pedonale 3', presence_relevant: false)
    Sensor.create(number: 12, name: 'Cancello/sbarre', presence_relevant: false)
    Sensor.create(number: 13, name: 'Cancello/sbarre', presence_relevant: false)
    Sensor.create(number: 14, name: 'Uscita 19', presence_relevant: false)
    Sensor.create(number: 15, name: 'Sensore 15', presence_relevant: false)
    Sensor.create(number: 16, name: 'Sbarre', presence_relevant: false)
    Sensor.create(number: 17, name: 'Sensore 17', presence_relevant: false)
    Sensor.create(number: 18, name: 'Presenza officina', presence_relevant: true)
    Sensor.create(number: 19, name: 'Presenza ufficio', presence_relevant: true)
    Sensor.create(number: 20, name: 'Uff./mag. 3° piano 1', presence_relevant: false)
    Sensor.create(number: 21, name: 'Uff./mag. 3° piano 2', presence_relevant: false)
    Sensor.create(number: 22, name: 'Ingresso officina', presence_relevant: false)
    Sensor.create(number: 23, name: 'Sensore 23', presence_relevant: false)
    Sensor.create(number: 24, name: 'Corridoio bagni', presence_relevant: false)
    Sensor.create(number: 25, name: 'Sensore 25', presence_relevant: false)
    Sensor.create(number: 26, name: 'Sensore 26', presence_relevant: false)
    Sensor.create(number: 27, name: 'Sensore 27', presence_relevant: false)
    Sensor.create(number: 28, name: 'Blocco pedonale', presence_relevant: false)
    Sensor.create(number: 29, name: 'Cancello/sbarre', presence_relevant: false)
    Sensor.create(number: 30, name: 'Uscita 18', presence_relevant: false)
    Sensor.create(number: 31, name: 'Disabilitato', presence_relevant: false)
    Sensor.create(number: 32, name: 'Disabilitato', presence_relevant: false)
    Sensor.create(number: 33, name: 'Disabilitato', presence_relevant: false)
    Sensor.create(number: 34, name: 'Blocco carraio', presence_relevant: false)
    Sensor.create(number: 35, name: 'Sensore 35', presence_relevant: false)
    Sensor.create(number: 36, name: 'Sensore 36', presence_relevant: false)
    Sensor.create(number: 37, name: 'Sensore 37', presence_relevant: false)
    Sensor.create(number: 38, name: 'Sensore 38', presence_relevant: false)
    Sensor.create(number: 39, name: 'Ingresso officina', presence_relevant: false)



    create_table :presence_timestamps do |t|
      t.references :badge, foreign_key: true, null: false, index: true
      t.datetime :time, null: true
      t.references :sensor, foreign_key: true, null: false, index: true
      t.boolean :deleted, null: true, default: false
      t.boolean :added, null: true, default: false
      t.string :file, null: false
      t.integer :row, null: false

      t.timestamps
    end
    add_index :presence_timestamps, [:badge_id,:time,:sensor_id], unique: true
  end


end
