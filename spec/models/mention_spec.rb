require 'rails_helper'

RSpec.describe Mention, type: :model do
  let(:campaign) { create(:campaign) }
  let(:entity) { create(:entity, campaign: campaign) }
  let(:page) { create(:page, campaign: campaign) }

  it "associates an entity with a polymorphic mentionable" do
    m = Mention.create!(entity: entity, mentionable: page, position: 0)
    expect(m.mentionable).to eq(page)
    expect(m.entity).to eq(entity)
  end

  it "is reachable through page.mentioned_entities" do
    Mention.create!(entity: entity, mentionable: page, position: 0)
    expect(page.mentioned_entities).to include(entity)
  end

  it "is reachable through entity.pages_mentioning" do
    Mention.create!(entity: entity, mentionable: page, position: 0)
    expect(entity.pages_mentioning).to include(page)
  end
end
