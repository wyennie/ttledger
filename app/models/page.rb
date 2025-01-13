class Page < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: [ :slugged, :history ]

  belongs_to :parent, class_name: "Page", optional: true
  belongs_to :campaign

  acts_as_list scope: :parent
  acts_as_tree order: :position

  scope :top_level, -> { where(parent_id: nil).order(:position) }

  def slug_candidates
    title.present? ? [ title ] : [ "untitled-page-#{id || SecureRandom.hex(4)}" ]
  end

  def should_generate_new_friendly_id?
    title_changed? || slug.blank?
  end
end
