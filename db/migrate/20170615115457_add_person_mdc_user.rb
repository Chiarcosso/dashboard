class AddPersonMdcUser < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :mdc_user, :string, null: true, default: nil
  end
end
