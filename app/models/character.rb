class Character < ApplicationRecord
  belongs_to :user
  belongs_to :campaign

  validates :name,  presence: true, length: { maximum: 50 }

  def assign_user(current_user)
    self.user = current_user
  end
end
