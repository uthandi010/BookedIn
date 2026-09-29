require "rails_helper"

RSpec.describe BusinessHour, type: :model do
  it "is valid with a day of week and an end after the start" do
    expect(build(:business_hour)).to be_valid
  end

  it "rejects a day of week outside 0..6" do
    expect(build(:business_hour, day_of_week: 7)).not_to be_valid
    expect(build(:business_hour, day_of_week: -1)).not_to be_valid
  end

  it "requires the end time to be after the start time" do
    expect(build(:business_hour, start_minute: 540, end_minute: 540)).not_to be_valid
    expect(build(:business_hour, start_minute: 600, end_minute: 540)).not_to be_valid
  end

  it "only allows one row per business per day of week" do
    business = create(:business)
    create(:business_hour, business: business, day_of_week: 1)
    duplicate = build(:business_hour, business: business, day_of_week: 1)
    expect(duplicate).not_to be_valid
  end

  describe "label helpers" do
    it "formats minutes-since-midnight as HH:MM" do
      hour = build(:business_hour, start_minute: 9 * 60, end_minute: 17 * 60 + 30)
      expect(hour.start_label).to eq("09:00")
      expect(hour.end_label).to eq("17:30")
    end

    it "parses HH:MM back into minutes-since-midnight" do
      expect(BusinessHour.label_to_minutes("09:00")).to eq(540)
      expect(BusinessHour.label_to_minutes("17:30")).to eq(1050)
    end
  end
end
