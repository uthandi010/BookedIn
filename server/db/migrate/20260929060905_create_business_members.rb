class CreateBusinessMembers < ActiveRecord::Migration[8.1]
  def change
    create_table :business_members do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :business_members, [:business_id, :user_id], unique: true
  end
end
