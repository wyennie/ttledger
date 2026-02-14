require 'rails_helper'

RSpec.describe "EntityKinds", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:campaign) do
    c = create(:campaign)
    create(:role, user: user, campaign: c, role_type: :gamemaster)
    c
  end

  before do
    post login_path, params: { session: { email: user.email, password: "password123" } }
  end

  it "creates a new kind" do
    expect {
      post campaign_entity_kinds_path(campaign), params: { entity_kind: { name: "Deity" } }
    }.to change(campaign.entity_kinds, :count).by(1)
    expect(campaign.entity_kinds.find_by(name: "deity")).to be_present
  end

  it "renames a kind" do
    kind = create(:entity_kind, campaign: campaign, name: "old")
    patch campaign_entity_kind_path(campaign, kind), params: { entity_kind: { name: "new" } }
    expect(kind.reload.name).to eq("new")
  end

  it "deletes an unused kind" do
    kind = create(:entity_kind, campaign: campaign, name: "unused")
    delete campaign_entity_kind_path(campaign, kind)
    expect(EntityKind.where(id: kind.id)).to be_empty
  end

  it "blocks deletion when entities reference the kind" do
    kind = create(:entity_kind, campaign: campaign, name: "in-use")
    create(:entity, campaign: campaign, entity_kind: kind)
    delete campaign_entity_kind_path(campaign, kind)
    expect(EntityKind.find(kind.id)).to be_present
    follow_redirect!
    expect(response.body).to include("Cannot delete")
  end
end
