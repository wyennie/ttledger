class Page < ApplicationRecord
  belongs_to :parent, class_name: "Page", optional: true
  belongs_to :campaign

  acts_as_list scope: :parent
  acts_as_tree order: :position

  scope :top_level, -> { where(parent_id: nil).order(:position) }

  after_create :create_slug
  before_update :update_slug

  def to_param
    slug
  end

  private

    def create_slug
      update_slug
      save!
    end

    def update_slug
      self.slug = [ title&.parameterize, id ].compact.join("-")
    end
end
