require 'rails_helper'

RSpec.describe "Campaigns", type: :request do
  let!(:user) { create(:user) }
  let(:campaign) { create(:campaign) }

  def log_in_as(user)
    post login_path, params: { session: { email: user.email, password: user.password } }
  end

  before do
    log_in_as(user) # Simulate user login
  end

  describe "POST /campaigns" do
    let(:valid_params) { { campaign: attributes_for(:campaign) } }
    let(:invalid_params) { { campaign: { name: '' } } }

    context "with valid parameters" do
      it "creates a new campaign" do
        expect { post campaigns_path, params: valid_params }.to change(Campaign, :count).by(1)
      end

      it "redirects to the campaign's show page" do
        post campaigns_path, params: valid_params
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(campaign_path(Campaign.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a campaign" do
        expect { post campaigns_path, params: invalid_params }.not_to change(Campaign, :count)
      end
    end
  end

  describe "PUT /campaigns/:id" do
    let(:update_params) { { campaign: { name: "Updated Name" } } }

    context "when the campaign exists" do
      it "updates the campaign" do
        put campaign_path(campaign), params: update_params
        expect(response).to redirect_to(campaign_path(campaign))
        campaign.reload
        expect(campaign.name).to eq("Updated Name")
      end
    end

    context "with invalid parameters" do
      it "does not update the campaign" do
        put campaign_path(campaign), params: { campaign: { name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(campaign.reload.name).not_to eq('')
      end
    end
  end

  describe "DELETE /campaigns/:id" do
    context "when the campaign exists" do
      it "deletes the campaign" do
        campaign
        expect { delete campaign_path(campaign) }.to change(Campaign, :count).by(-1)
      end

      it "redirects to the campaigns index" do
        delete campaign_path(campaign)
        expect(response).to redirect_to(user)
        expect(response).to have_http_status(:see_other)
      end
    end

    context "when the campaign does not exist" do
      it "returns a 404 status" do
        delete campaign_path(9999)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("Campaign not found")
      end
    end
  end
end
