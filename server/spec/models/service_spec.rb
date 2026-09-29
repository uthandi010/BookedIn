require "rails_helper"

RSpec.describe Service, type: :model do
  it "is valid with a name, positive duration, and business" do
    expect(build(:service)).to be_valid
  end

  it "requires a positive duration" do
    expect(build(:service, duration_minutes: 0)).not_to be_valid
    expect(build(:service, duration_minutes: -15)).not_to be_valid
  end

  it "does not allow a negative price" do
    expect(build(:service, price_cents: -100)).not_to be_valid
  end

  it "allows a nil price (free service)" do
    expect(build(:service, price_cents: nil)).to be_valid
  end

  describe ".active" do
    it "only returns services flagged active" do
      business = create(:business)
      visible = create(:service, business: business, active: true)
      create(:service, business: business, active: false)

      expect(business.services.active).to contain_exactly(visible)
    end
  end
end
