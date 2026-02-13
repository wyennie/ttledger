class EntityKind < ApplicationRecord
  DEFAULTS = %w[character location faction item organization other].freeze

  belongs_to :campaign
  has_many :entities, dependent: :restrict_with_error

  validates :name, presence: true,
                   length: { maximum: 60 },
                   uniqueness: { scope: :campaign_id, case_sensitive: false }

  before_validation :normalize_name

  def self.seed_defaults_for(campaign)
    DEFAULTS.each do |name|
      campaign.entity_kinds.find_or_create_by!(name: name)
    end
  end

  private

    def normalize_name
      self.name = name.to_s.strip.downcase.presence
    end
end
