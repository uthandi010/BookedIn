require "rails_helper"

RSpec.describe BusinessMember, type: :model do
  it "is valid with a business, user, and role" do
    expect(build(:business_member)).to be_valid
  end

  it "does not allow the same user to join a business twice" do
    business = create(:business)
    user = create(:user)
    create(:business_member, business: business, user: user)

    duplicate = build(:business_member, business: business, user: user)
    expect(duplicate).not_to be_valid
  end

  it "allows the same user to be a member of two different businesses" do
    user = create(:user)
    create(:business_member, business: create(:business), user: user)

    second_membership = build(:business_member, business: create(:business), user: user)
    expect(second_membership).to be_valid
  end

  it "exposes staff/owner as an enum" do
    member = create(:business_member, role: :owner)
    expect(member).to be_owner
    expect(member).not_to be_staff
  end
end
