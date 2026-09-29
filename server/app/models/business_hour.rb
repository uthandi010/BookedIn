class BusinessHour < ApplicationRecord
  MINUTES_PER_DAY = 24 * 60

  belongs_to :business

  validates :day_of_week, inclusion: { in: 0..6 }, uniqueness: { scope: :business_id }
  validates :start_minute, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :end_minute, numericality: { only_integer: true, less_than_or_equal_to: MINUTES_PER_DAY }
  validate :end_after_start

  # "09:00" style formatting for the API, so the frontend never has to do
  # minutes-since-midnight math itself.
  def start_label
    self.class.minutes_to_label(start_minute)
  end

  def end_label
    self.class.minutes_to_label(end_minute)
  end

  def self.minutes_to_label(minutes)
    format("%02d:%02d", minutes / 60, minutes % 60)
  end

  def self.label_to_minutes(label)
    hours, mins = label.to_s.split(":").map(&:to_i)
    (hours * 60) + mins
  end

  private

  def end_after_start
    return if start_minute.nil? || end_minute.nil?
    errors.add(:end_minute, "must be after the start time") if end_minute <= start_minute
  end
end
