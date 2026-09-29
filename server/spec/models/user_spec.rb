require "rails_helper"

RSpec.describe User, type: :model do
  it "is valid with a name, email, and password" do
    user = build(:user)
    expect(user).to be_valid
  end

  it "requires a unique email" do
    create(:user, email: "duplicate@example.com")
    duplicate = build(:user, email: "duplicate@example.com")
    expect(duplicate).not_to be_valid
  end

  it "downcases and strips the email before validation" do
    user = build(:user, email: "  MixedCase@Example.com  ")
    user.valid?
    expect(user.email).to eq("mixedcase@example.com")
  end

  it "requires a password of at least 8 characters" do
    user = build(:user, password: "short")
    expect(user).not_to be_valid
  end

  it "hashes the password so it is never stored in plain text" do
    user = create(:user, password: "Password123!")
    expect(user.password_digest).not_to eq("Password123!")
    expect(user.authenticate("Password123!")).to eq(user)
    expect(user.authenticate("WrongPassword!")).to be false
  end
end
