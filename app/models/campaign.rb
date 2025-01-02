class Campaign < ApplicationRecord
  has_many :roles, dependent: :destroy
  has_many :users, through: :roles
  has_many :characters, dependent: :destroy
  has_many :pages

  has_many :campaign_invitations, dependent: :destroy

  validates :name, presence: true
end
