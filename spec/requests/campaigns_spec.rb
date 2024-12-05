require 'rails_helper'

RSpec.describe "Campaigns", type: :request do
  let(:user) { FactoryBot.create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /new" do
    it "returns http success" do
      get "/campaigns/new"
      expect(response).to have_http_status(:success)
    end
  end
end
