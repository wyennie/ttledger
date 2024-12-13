class Item < ApplicationRecord
  belongs_to :character
  belongs_to :item_type, polymorphic: true
  belongs_to :container, class_name: "Item", optional: true
  has_many :contained_items, class_name: "Item", foreign_key: "container_id"

  after_initialize :set_default_item_type, if: :new_record?

  validates :name, length: { maximum: 100 }, allow_blank: true
  validates :description, length: { maximum: 500 }, allow_blank: true
  validates :weight, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :item_type, presence: true
  validate :cannot_contain_itself

  private
    def cannot_contain_itself
      if container_id.present? && container_id == id
        errors.add(:container, "cannot be the same as the item itself")
      end
    end

    def set_default_item_type
      self.item_type ||= ItemType.find_or_create_by(name: "Misc")
    end
end
