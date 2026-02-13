class SeedDefaultEntityKinds < ActiveRecord::Migration[8.0]
  def up
    Campaign.find_each { |c| EntityKind.seed_defaults_for(c) }
  end

  def down
    EntityKind.where(name: EntityKind::DEFAULTS).delete_all
  end
end
