require 'rails_helper'

RSpec.describe EntityKind, type: :model do
  let(:campaign) { create(:campaign) }

  it "has a valid factory" do
    kind = create(:entity_kind, campaign: campaign)
    expect(kind).to be_persisted
  end

  describe "validations" do
    it "requires a name" do
      kind = EntityKind.new(campaign: campaign, name: nil)
      expect(kind).not_to be_valid
    end

    it "normalizes name to downcased and stripped" do
      kind = EntityKind.create!(campaign: campaign, name: "  Deity  ")
      expect(kind.name).to eq("deity")
    end

    it "is unique per campaign (case-insensitive)" do
      EntityKind.create!(campaign: campaign, name: "Cult")
      dup = EntityKind.new(campaign: campaign, name: "cult")
      expect(dup).not_to be_valid
    end

    it "allows the same name in different campaigns" do
      other = create(:campaign)
      EntityKind.create!(campaign: campaign, name: "deity")
      expect(EntityKind.create(campaign: other, name: "deity")).to be_persisted
    end
  end

  describe ".seed_defaults_for" do
    it "creates the default kinds for a campaign" do
      campaign = create(:campaign)
      campaign.entity_kinds.delete_all
      EntityKind.seed_defaults_for(campaign)
      expect(campaign.entity_kinds.pluck(:name)).to match_array(EntityKind::DEFAULTS)
    end

    it "is idempotent" do
      EntityKind.seed_defaults_for(campaign)
      expect { EntityKind.seed_defaults_for(campaign) }.not_to change(campaign.entity_kinds, :count)
    end
  end

  describe "deletion" do
    it "cannot be deleted while entities reference it" do
      kind = create(:entity_kind, campaign: campaign)
      create(:entity, campaign: campaign, entity_kind: kind)
      expect(kind.destroy).to be(false)
      expect(kind.errors[:base].first).to include("dependent")
    end

    it "can be deleted when no entities reference it" do
      kind = create(:entity_kind, campaign: campaign)
      expect(kind.destroy).to be_truthy
    end
  end

  describe "campaign auto-seeding" do
    it "seeds default kinds for new campaigns" do
      campaign = build(:campaign)
      campaign.save!
      expect(campaign.entity_kinds.pluck(:name)).to include(*EntityKind::DEFAULTS)
    end
  end
end
