require 'rails_helper'

RSpec.describe Entity, type: :model do
  let(:campaign) { create(:campaign) }
  let(:kind) { campaign.entity_kinds.find_by(name: "character") }

  it "has a valid factory" do
    expect(create(:entity, campaign: campaign)).to be_persisted
  end

  describe "slug" do
    it "generates a slug from the name, scoped to campaign" do
      e = Entity.create!(campaign: campaign, entity_kind: kind, name: "Aria Stormwind")
      expect(e.slug).to eq("aria-stormwind")
    end

    it "lets two campaigns share the same name/slug" do
      Entity.create!(campaign: campaign, entity_kind: kind, name: "Aria")
      other = create(:campaign)
      other_kind = other.entity_kinds.find_by(name: "character")
      e2 = Entity.create!(campaign: other, entity_kind: other_kind, name: "Aria")
      expect(e2.slug).to eq("aria")
    end
  end

  describe "validations" do
    it "rejects an entity_kind from a different campaign" do
      other = create(:campaign)
      other_kind = other.entity_kinds.find_by(name: "character")
      e = Entity.new(campaign: campaign, entity_kind: other_kind, name: "Cross")
      expect(e).not_to be_valid
      expect(e.errors[:entity_kind]).to be_present
    end

    it "rejects a bio_page from a different campaign" do
      other = create(:campaign)
      other_page = create(:page, campaign: other)
      e = Entity.new(campaign: campaign, entity_kind: kind, name: "X", bio_page: other_page)
      expect(e).not_to be_valid
      expect(e.errors[:bio_page]).to be_present
    end

    it "is unique per campaign by name" do
      Entity.create!(campaign: campaign, entity_kind: kind, name: "Aria")
      dup = Entity.new(campaign: campaign, entity_kind: kind, name: "aria")
      expect(dup).not_to be_valid
    end
  end

  describe "associations" do
    it "destroys mentions when destroyed" do
      e = create(:entity, campaign: campaign)
      page = create(:page, campaign: campaign, body: %{<span data-mention="entity" data-entity-id="#{e.id}" data-entity-type="character">@x</span>})
      expect(e.mentions.count).to eq(1)
      e.destroy
      expect(Mention.where(entity_id: e.id)).to be_empty
    end
  end
end
