class Page < ApplicationRecord
  belongs_to :parent, class_name: 'Page', optional: true
  belongs_to :campaign

  acts_as_list scope: :parent

  before_save :update_slug

  has_many :children, class_name: "Page", foreign_key: "parent_id"

  def to_param
    slug
  end

  private

    def update_slug
      self.slug = title.parameterize
    end
end
