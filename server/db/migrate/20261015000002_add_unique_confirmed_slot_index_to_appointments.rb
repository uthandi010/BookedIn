class AddUniqueConfirmedSlotIndexToAppointments < ActiveRecord::Migration[8.1]
  # Database-level backstop against double booking: two confirmed
  # appointments can never share a business and start time, even if two
  # requests race past the application-level overlap check.
  def change
    add_index :appointments, [ :business_id, :starts_at ],
              unique: true,
              where: "status = 0",
              name: "index_appointments_on_business_and_start_when_confirmed"
  end
end
