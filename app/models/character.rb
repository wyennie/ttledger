class Character < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  has_many :items

  validates :name,  presence: true, length: { maximum: 50 }

  def assign_user(current_user)
    self.user = current_user
  end
end
