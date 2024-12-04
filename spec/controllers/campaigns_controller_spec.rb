require "rails_helper"

RSpec.describe CampaignsController, type: :controller do
  let(:campaign) { create(:campaign) }
  let(:params)   { { campaign: FactoryBot.attributes_for(:campaign) } }

  describe '#create' do
    context 'when valid parameters are provided' do
      it 'creates a new campaign' do
        expect { post :create, params: params }.to change(Campaign, :count).by(1)
      end

      it 'responds with a 302 status code' do
        post :create, params: params
        expect(response).to have_http_status(:found)
      end
    end

    context 'when invalid parameters are provided' do
      let(:invalid_params) { { campaign: { name: '' } } }

      it 'does not create a campaign' do
        expect { post :create, params: invalid_params }.not_to change(Campaign, :count)
      end

      it 'responds with a 422 status code' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

=begin
  describe '#update' do
    context 'when campaign exists' do
      it 'updates the campaign with valid params' do
        put :update, params: { id: campaign.id, campaign: { name: 'Updated Name' } }
        campaign.reload
        expect(campaign.name).to eq('Updated Name')
      end

      it 'responds with a 200 status code' do
        put :update, params: { id: campaign.id, campaign: { name: 'Updated Name' } }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when campaign does not exist' do
      it 'responds with a 404 status code' do
        put :update, params: { id: 9999, campaign: { name: 'Non-existent Campaign' } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
=end

=begin
  describe '#destroy' do
    context 'when campaign exists' do
      it 'deletes the campaign' do
        campaign
        expect { delete :destroy, params: { id: campaign.id } }.to change(Campaign, :count).by(-1)
      end

      it 'responds with a 204 status code' do
        delete :destroy, params: { id: campaign.id }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'when campaign does not exist' do
      it 'responds with a 404 status code' do
        delete :destroy, params: { id: 9999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
=end
end
