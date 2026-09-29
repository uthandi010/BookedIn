class Appointment < ApplicationRecord
  belongs_to :business
  belongs_to :service
  belongs_to :staff, class_name: "User", foreign_key: :staff_user_id, optional: true

  enum :status, { confirmed: 0, cancelled: 1 }

  validates :customer_name, presence: true
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts
  validate :no_overlap_with_existing_confirmed_appointment, on: :create

  # Two confirmed appointments on the same business (optionally narrowed to
  # the same staff member) overlap if one starts before the other ends.
  def self.overlapping(business_id:, starts_at:, ends_at:, staff_user_id: nil)
    scope = confirmed.where(business_id: business_id)
                      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
    scope = scope.where(staff_user_id: staff_user_id) if staff_user_id.present?
    scope
  end

  private

  def ends_after_starts
    return if starts_at.nil? || ends_at.nil?
    errors.add(:ends_at, "must be after the start time") if ends_at <= starts_at
  end

  def no_overlap_with_existing_confirmed_appointment
    return if starts_at.nil? || ends_at.nil? || business_id.nil?

    conflict = self.class.overlapping(
      business_id: business_id, starts_at: starts_at, ends_at: ends_at, staff_user_id: staff_user_id
    ).exists?

    errors.add(:base, "This time slot is no longer available") if conflict
  end
end
