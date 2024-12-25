# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  # Subject definition for reusable user instance
  subject(:user) { build(:user) }

  # Validation tests
  describe 'validations' do
    context 'when the user has valid attributes' do
      it { is_expected.to be_valid }
    end

    context 'when the user does not have a name' do
      before { user.name = nil }

      it { is_expected.to_not be_valid }
    end

    context 'when the user does not have an email' do
      before { user.email = nil }

      it { is_expected.to_not be_valid }
    end
  end

  # Authenticated? 
  describe '#authenticated?' do
    let!(:user) { create(:user, :with_remember_token) }

    context 'when remember_digest is nil' do
      before do
        user.update(remember_digest: nil)
      end

      it 'returns false' do
        expect(user.authenticated?('some_token')).to be false
      end
    end

    context 'when remember_digest is present' do

      it 'returns true if the token is valid' do
        allow(BCrypt::Password).to receive(:new).with(user.remember_digest).and_return(double(is_password?: true))
        expect(user.authenticated?(user.remember_token)).to be true
      end

      it 'returns false if the token is invalid' do
        allow(BCrypt::Password).to receive(:new).with(user.remember_digest).and_return(double(is_password?: false))
        expect(user.authenticated?('invalid_token')).to be false
      end
    end
  end

  # self.digest
  describe '.digest' do
    let(:password) { 'password123' }

    it 'creates a BCrypt password hash with correct cost' do
      # Mock the cost to be 12 (or any specific value you need for your test)
      allow(ActiveModel::SecurePassword).to receive(:min_cost).and_return(false)
      allow(BCrypt::Password).to receive(:create).with(password, cost: 12).and_return('hashed_password')

      digest = User.digest(password)
      expect(digest).to eq('hashed_password')
    end

    it 'uses minimum cost when ActiveModel::SecurePassword.min_cost is true' do
      allow(ActiveModel::SecurePassword).to receive(:min_cost).and_return(true)
      allow(BCrypt::Password).to receive(:create).with(password, cost: BCrypt::Engine::MIN_COST).and_return('hashed_password')

      digest = User.digest(password)
      expect(digest).to eq('hashed_password')
    end

    it 'uses normal cost when ActiveModel::SecurePassword.min_cost is false' do
      allow(ActiveModel::SecurePassword).to receive(:min_cost).and_return(false)
      allow(BCrypt::Password).to receive(:create).with(password, cost: 12).and_return('hashed_password')

      digest = User.digest(password)
      expect(digest).to eq('hashed_password')
    end
  end

  # Password encryption tests
  describe '#password_digest' do
    context 'when a user is created' do
      it 'encrypts the password' do
        user = create(:user, password: 'securepassword', password_confirmation: 'securepassword')
        expect(user.password_digest).to_not eq('securepassword')
      end
    end
  end


  # self.new_token
  describe '.new_token' do
    it 'returns a URL-safe base64 string' do
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('mocked_token')

      token = User.new_token
      expect(token).to eq('mocked_token')
    end
  end

  # remember
  describe '#remember' do
    let!(:user) { create(:user) }

    it 'generates a remember_token and updates the remember_digest' do
      allow(User).to receive(:new_token).and_return('test_token')
      allow(User).to receive(:digest).with('test_token').and_return('hashed_test_token')

      user.remember

      expect(user.remember_token).to eq('test_token')
      expect(user.remember_digest).to eq('hashed_test_token')
    end
  end

  # create_confirmation_token
  describe '#create_confirmation_token' do
    let!(:user) { create(:user) }

    it 'creates a confirmation token' do
      user.create_confirmation_token
      expect(user.confirmation_token).not_to be_nil
    end
  end

  # send_confrimation_email
  describe '#send_confirmation_email' do
    let(:user) { create(:user) }

    it 'sends a confirmation email' do
      mailer = double('UserMailer')
      allow(UserMailer).to receive(:confirmation_email).with(user).and_return(mailer)
      expect(mailer).to receive(:deliver_now)

      user.send_confirmation_email
    end
  end

  # confirm_email
  describe '#confirm_email' do
    let(:user) { create(:user, confirmation_token: 'sample_token') }

    context 'when the confirmation is successful' do
      it 'sets confirmed_at and removes confirmation_token' do
        user.confirm_email

        expect(user.confirmed_at).not_to be_nil
        expect(user.confirmation_token).to be_nil
      end
    end

    context 'when the confirmation fails' do
      it 'raises an error and logs the failure' do
        allow(user).to receive(:update_attribute).with(:confirmed_at, anything).and_return(false)

        expect(Rails.logger).to receive(:error).with(/User #{user.id} confirmation failed:/)

        expect { user.confirm_email }.to raise_error(ActiveRecord::Rollback)
      end
    end
  end

  # Testing edge cases (e.g., invalid attributes)
  describe 'email format' do
    context 'when email is invalid' do
      it 'does not allow invalid email formats' do
        user.email = 'invalidemail'
        expect(user).to_not be_valid
      end
    end

    context 'when email is valid' do
      it 'allows valid email formats' do
        user.email = 'valid@example.com'
        expect(user).to be_valid
      end
    end
  end

  # Testing the uniqueness of the email
  describe 'email uniqueness' do
    context 'when the email is already taken' do
      let!(:existing_user) { create(:user, email: 'existing@example.com') }

      it 'does not allow duplicate emails' do
        user.email = 'existing@example.com'
        expect(user).to_not be_valid
      end
    end
  end


  # forget
  describe '#forget' do
    let!(:user) { create(:user, :with_remember_token) }

    it 'sets the remember_digest to nil' do
      expect(user.remember_digest).not_to be_nil
      user.forget
      expect(user.remember_digest).to be_nil
    end
  end
end
