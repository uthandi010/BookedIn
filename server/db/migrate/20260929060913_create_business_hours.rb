class CreateBusinessHours < ActiveRecord::Migration[8.1]
  def change
    create_table :business_hours do |t|
      t.references :business, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.integer :start_minute, null: false
      t.integer :end_minute, null: false

      t.timestamps
    end
    add_index :business_hours, [:business_id, :day_of_week], unique: true
  end
end
