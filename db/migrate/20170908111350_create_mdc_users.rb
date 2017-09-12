class CreateMdcUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :mdc_users do |t|
      t.string :user, null: false, unique: true
      t.string :activation_code, null: false, unique: true
      t.references :assigned_to_company, foreign_key: {to_table: :companies}
      t.references :assigned_to_person, foreign_key: {to_table: :people}

      t.timestamps
    end
  end
end
