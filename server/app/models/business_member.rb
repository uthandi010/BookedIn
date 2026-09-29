class BusinessMember < ApplicationRecord
  belongs_to :business
  belongs_to :user

  enum :role, { staff: 0, owner: 1 }

  validates :user_id, uniqueness: { scope: :business_id, message: "is already a member of this business" }
end
