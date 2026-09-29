class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :duration_minutes, null: false
      t.integer :price_cents
      t.text :description
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
