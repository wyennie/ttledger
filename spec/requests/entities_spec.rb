require 'rails_helper'

RSpec.describe "Entities", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:campaign) do
    c = create(:campaign)
    create(:role, user: user, campaign: c, role_type: :gamemaster)
    c
  end

  before do
    post login_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /campaigns/:id/entities" do
    it "lists entities grouped by kind" do
      kind = campaign.entity_kinds.find_by(name: "character")
      create(:entity, campaign: campaign, name: "Aria", entity_kind: kind)

      get campaign_entities_path(campaign)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Aria")
    end

    it "rejects users who are not members of the campaign" do
      stranger_campaign = create(:campaign)
      get campaign_entities_path(stranger_campaign)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /campaigns/:id/entities" do
    it "creates an entity" do
      kind = campaign.entity_kinds.find_by(name: "character")
      expect {
        post campaign_entities_path(campaign),
             params: { entity: { name: "Aria", entity_kind_id: kind.id, summary: "rogue" } }
      }.to change(campaign.entities, :count).by(1)
    end
  end

  describe "GET /campaigns/:id/entities/suggestions" do
    let!(:aria) { create(:entity, campaign: campaign, name: "Aria") }
    let!(:bren) { create(:entity, campaign: campaign, name: "Bren") }

    it "returns campaign-scoped JSON results" do
      get suggestions_campaign_entities_path(campaign), params: { q: "ar" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.map { |r| r["name"] }).to eq([ "Aria" ])
      expect(json.first.keys).to match_array(%w[id name kind slug])
    end

    it "returns up to 10 results when no query is provided" do
      15.times { |i| create(:entity, campaign: campaign, name: "Entity #{i}") }
      get suggestions_campaign_entities_path(campaign)
      expect(JSON.parse(response.body).size).to eq(10)
    end

    it "excludes entities from other campaigns" do
      other = create(:campaign)
      create(:entity, campaign: other, name: "Aria")
      get suggestions_campaign_entities_path(campaign), params: { q: "Aria" }
      json = JSON.parse(response.body)
      expect(json.map { |r| r["id"] }).to eq([ aria.id ])
    end
  end

  describe "DELETE /campaigns/:id/entities/:slug" do
    it "deletes the entity and cascades mentions" do
      e = create(:entity, campaign: campaign)
      page = create(:page, campaign: campaign,
        body: %(<span data-mention="entity" data-entity-id="#{e.id}" data-entity-type="character">@x</span>))
      expect(page.mentions.count).to eq(1)

      delete campaign_entity_path(campaign, e)
      expect(Entity.where(id: e.id)).to be_empty
      expect(Mention.where(entity_id: e.id)).to be_empty
    end
  end
end
