class Entity < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: [ :slugged, :scoped, :history ], scope: :campaign

  belongs_to :campaign
  belongs_to :entity_kind
  belongs_to :bio_page, class_name: "Page", optional: true

  has_many :mentions, dependent: :destroy
  has_many :pages_mentioning,
           -> { where(mentions: { mentionable_type: "Page" }) },
           through: :mentions,
           source: :mentionable,
           source_type: "Page"

  validates :name, presence: true, length: { maximum: 120 }
  validates :name, uniqueness: { scope: :campaign_id, case_sensitive: false }
  validate  :entity_kind_belongs_to_campaign
  validate  :bio_page_belongs_to_campaign

  def slug_candidates
    [
      name,
      [ name, entity_kind&.name ],
      [ name, entity_kind&.name, SecureRandom.hex(2) ]
    ]
  end

  def should_generate_new_friendly_id?
    name_changed? || slug.blank?
  end

  private

    def entity_kind_belongs_to_campaign
      return if entity_kind.nil? || campaign_id.nil?
      errors.add(:entity_kind, "must belong to the same campaign") if entity_kind.campaign_id != campaign_id
    end

    def bio_page_belongs_to_campaign
      return if bio_page.nil? || campaign_id.nil?
      errors.add(:bio_page, "must belong to the same campaign") if bio_page.campaign_id != campaign_id
    end
end
