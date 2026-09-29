require "rails_helper"

RSpec.describe Business, type: :model do
  it "is valid with a name, slug, and owner" do
    expect(build(:business)).to be_valid
  end

  it "requires a unique slug" do
    create(:business, slug: "acme-inc")
    duplicate = build(:business, slug: "acme-inc")
    expect(duplicate).not_to be_valid
  end

  it "rejects slugs with spaces or underscores" do
    ["acme_inc", "acme inc"].each do |bad_slug|
      expect(build(:business, slug: bad_slug)).not_to be_valid
    end
  end

  it "accepts slugs with lowercase letters, numbers, and hyphens" do
    expect(build(:business, slug: "acme-inc-2")).to be_valid
  end

  it "downcases the slug before validation" do
    business = build(:business, slug: "ACME-Inc")
    business.valid?
    expect(business.slug).to eq("acme-inc")
  end

  describe "#role_for" do
    it "returns the member's role, or nil for a non-member" do
      business = create(:business)
      member = create(:user)
      create(:business_member, business: business, user: member, role: :staff)
      outsider = create(:user)

      expect(business.role_for(member)).to eq("staff")
      expect(business.role_for(outsider)).to be_nil
    end
  end
end
