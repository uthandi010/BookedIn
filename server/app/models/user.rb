class User < ApplicationRecord
  has_secure_password

  has_many :business_memberships, class_name: "BusinessMember", dependent: :destroy
  has_many :businesses, through: :business_memberships
  has_many :owned_businesses, class_name: "Business", foreign_key: :owner_id, dependent: :restrict_with_error

  before_validation { self.email = email.to_s.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || password.present? }

  def as_json_public
    { id: id, name: name, email: email }
  end
end
