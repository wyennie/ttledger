class Item < ApplicationRecord
  belongs_to :character
  belongs_to :item_type, polymorphic: true
  belongs_to :container, class_name: 'Item', optional: true
  has_many :contained_items, class_name: 'Item', foreign_key: 'container_id'

  after_initialize :set_default_item_type, if: :new_record?

  private

  def set_default_item_type
    self.item_type ||= ItemType.find_or_create_by(name: 'Misc')
  end
end
