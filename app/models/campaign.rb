class Campaign < ApplicationRecord
  has_many :roles, dependent: :destroy
  has_many :users, through: :roles
  has_many :characters, dependent: :destroy
  has_many :pages, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :entity_kinds, dependent: :destroy
  has_many :entities, dependent: :destroy

  has_many :campaign_invitations, dependent: :destroy

  validates :name, presence: true

  after_create :seed_default_entity_kinds

  private

    def seed_default_entity_kinds
      EntityKind.seed_defaults_for(self)
    end
end
