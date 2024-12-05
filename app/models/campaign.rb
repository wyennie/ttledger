class Campaign < ApplicationRecord
  has_many :roles, dependent: :destroy
  has_many :users, through: :roles
  has_many :characters, dependent: :destroy

  validates :name, presence: true
end
