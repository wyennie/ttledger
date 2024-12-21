class User < ApplicationRecord
  attr_accessor :remember_token

  has_many :sent_friend_requests, class_name: "Friendship", foreign_key: :sender_id
  has_many :received_friend_requests, class_name: "Friendship", foreign_key: :receiver_id

  has_many :friends, -> { where(status: "accepted") }, through: :sent_friend_requests, source: :receiver
  has_many :inverse_friends, -> { where(status: "accepted") }, through: :received_friend_requests, source: :sender

  has_many :characters
  has_many :roles
  has_many :campaigns, through: :roles

  before_save { self.email = email.downcase }
  before_create :create_confirmation_token

  validates :username, presence: true, length: { maximum: 50 },
                       uniqueness: true
  validates :name,     presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email,    presence: true, length: { maximum: 255 },
                       format: { with: VALID_EMAIL_REGEX },
                       uniqueness: true
  has_secure_password
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?
  validates :password_confirmation, presence: true, length: { minimum: 6 }, if: :password_required?

  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def self.new_token
    SecureRandom.urlsafe_base64
  end

  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def create_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
  end

  def send_confirmation_email
    UserMailer.confirmation_email(self).deliver_now
  end

  def confirm_email
    if update_attribute(:confirmed_at, Time.current) && update_attribute(:confirmation_token, nil)
      Rails.logger.info("User #{self.id} confirmed successfully.")
    else
      Rails.logger.error("User #{self.id} confirmation failed: #{errors.full_messages.join(', ')}")
      raise ActiveRecord::Rollback
    end
  end

  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  private

    def password_required?
      new_record? || password.present?
    end
end
