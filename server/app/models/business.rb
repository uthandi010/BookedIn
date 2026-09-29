class Business < ApplicationRecord
  SLUG_FORMAT = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  belongs_to :owner, class_name: "User"

  has_many :business_members, dependent: :destroy
  has_many :members, through: :business_members, source: :user
  has_many :services, dependent: :destroy
  has_many :business_hours, dependent: :destroy
  has_many :appointments, dependent: :destroy

  before_validation { self.slug = slug.to_s.strip.downcase }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT,
    message: "can only contain lowercase letters, numbers, and single hyphens" }

  def role_for(user)
    business_members.find_by(user_id: user.id)&.role
  end
end
