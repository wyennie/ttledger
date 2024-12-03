class Campaign < ApplicationRecord
  has_many :roles
  has_many :users, through: :roles
  has_many :characters

  validates :name, presence: true
end
