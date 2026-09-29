class Service < ApplicationRecord
  belongs_to :business
  has_many :appointments, dependent: :restrict_with_error

  scope :active, -> { where(active: true) }

  validates :name, presence: true
  validates :duration_minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
