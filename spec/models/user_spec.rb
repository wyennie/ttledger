require 'rails_helper'

RSpec.describe User, type: :model do
  describe "when creatng a new User" do
    let!(:user) { FactoryBot.create(:user) }

    it "user information should be valid" do
      expect(user.valid?).to eq true
    end

    it "name should not be an empty string" do
      user.name = "      "
      expect(user.valid?).to eq false
    end

    it "name shouldn't be too long" do
      user.name = "a" * 51
      expect(user.valid?).to eq false
    end

    it "validation should reject invalid emails" do
      invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
                             foo@bar_baz.com foo@bar+baz.com]
      invalid_addresses.each do | invalid_address |
        user.email = invalid_address
        expect(user.valid?).to eq false
      end
    end

    it "email should be valid" do
      expect(user.valid?).to eq true
    end

    it "email should not be empty string" do
      user.email = "     "
      expect(user.valid?).to eq false
    end

    it "email shouldn't be too long" do
      user.email = "a" * 256
      expect(user.valid?).to eq false
    end

    it "email should not be a duplicate" do
      duplicate_user = user.dup
      user.save
      expect(duplicate_user.valid?).to eq false
    end

    it "password should not be blank" do
      user.password = user.password_confirmation = " " * 6
      expect(user.valid?).to eq false
    end

    it "password should have a minimum length" do
      user.password = user.password_confirmation = "a" * 5
    end
  end
end
