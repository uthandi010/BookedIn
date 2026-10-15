class AddTimezoneToBusinesses < ActiveRecord::Migration[8.1]
  def change
    add_column :businesses, :timezone, :string, null: false, default: "UTC"
  end
end
