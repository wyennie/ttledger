require 'rails_helper'

RSpec.describe "Campaigns", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/campaigns/new"
      expect(response).to have_http_status(:success)
    end
  end
end
