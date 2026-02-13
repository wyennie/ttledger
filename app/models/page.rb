class Page < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]
  belongs_to :parent, class_name: "Page", optional: true
  belongs_to :campaign
  has_many :children, class_name: "Page", foreign_key: "parent_id", dependent: :destroy
  has_many :mentions, as: :mentionable, dependent: :destroy
  has_many :mentioned_entities, through: :mentions, source: :entity
  has_many :entities_with_bio, class_name: "Entity", foreign_key: :bio_page_id, dependent: :nullify
  acts_as_list scope: :parent
  acts_as_tree order: :position, dependent: :destroy

  scope :top_level, -> { where(parent_id: nil).order(:position) }

  after_commit :reindex_mentions, on: %i[create update], if: :saved_change_to_body?

  def slug_candidates
    title.present? ? [ title ] : [ "untitled-page-#{id || SecureRandom.hex(4)}" ]
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end

  private

    def reindex_mentions
      MentionExtractor.new(self).reindex!
    end
end
