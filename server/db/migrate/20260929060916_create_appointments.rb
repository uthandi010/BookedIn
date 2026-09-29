class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :business, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.integer :staff_user_id
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :appointments, [:business_id, :starts_at]
    add_index :appointments, :staff_user_id
  end
end
