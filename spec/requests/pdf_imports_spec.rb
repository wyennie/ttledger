require 'rails_helper'

RSpec.describe "PdfImports", type: :request do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:campaign) do
    c = create(:campaign)
    create(:role, user: user, campaign: c, role_type: :gamemaster)
    c
  end

  before do
    post login_path, params: { session: { email: user.email, password: "password123" } }
  end

  describe "GET /campaigns/:id/pdf_imports/new" do
    it "renders the upload form for the gamemaster" do
      get new_campaign_pdf_import_path(campaign)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Import a sourcebook")
    end

    it "blocks players from importing" do
      player = create(:user, confirmed_at: Time.current)
      create(:role, user: player, campaign: campaign, role_type: :player)
      delete logout_path
      post login_path, params: { session: { email: player.email, password: "password123" } }

      get new_campaign_pdf_import_path(campaign)
      expect(response).to redirect_to(campaign_path(campaign))
    end
  end

  describe "POST /campaigns/:id/pdf_imports" do
    let(:fake_pdf) do
      Rack::Test::UploadedFile.new(
        StringIO.new("%PDF-1.4\n% test\n"),
        "application/pdf",
        original_filename: "sourcebook.pdf"
      )
    end

    it "creates a pending import and redirects to the show page" do
      expect {
        post campaign_pdf_imports_path(campaign), params: { pdf_import: { pdf: fake_pdf } }
      }.to change(campaign.pdf_imports, :count).by(1)

      import = campaign.pdf_imports.last
      expect(import.status).to eq("pending")
      expect(import.original_filename).to eq("sourcebook.pdf")
      expect(import.pdf).to be_attached
      expect(response).to redirect_to(campaign_pdf_import_path(campaign, import))
    end

    it "rejects a non-pdf upload" do
      bogus = Rack::Test::UploadedFile.new(
        StringIO.new("hi"),
        "text/plain",
        original_filename: "evil.txt"
      )
      post campaign_pdf_imports_path(campaign), params: { pdf_import: { pdf: bogus } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /campaigns/:id/pdf_imports/:id" do
    it "shows the status panel" do
      import = create(:pdf_import, campaign: campaign, user: user)
      get campaign_pdf_import_path(campaign, import)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Status")
    end

    it "renders the proposed pages and entities once the draft is ready" do
      import = create(:pdf_import,
                      campaign: campaign,
                      user: user,
                      status: "ready_for_review",
                      draft_payload: {
                        "pages" => [
                          { "tmp_id" => "p1", "title" => "Overview", "parent_tmp_id" => nil, "source_pages" => [ 1, 2 ], "summary" => "Intro", "body" => "<h2>Welcome</h2>" },
                          { "tmp_id" => "p2", "title" => "Geography", "parent_tmp_id" => "p1", "source_pages" => [ 3, 4 ], "summary" => "Map", "body" => "<p>Mountains.</p>" }
                        ],
                        "entities" => [
                          { "tmp_id" => "e1", "name" => "Strahd", "kind" => "character", "summary" => "Vampire lord." }
                        ]
                      })

      get campaign_pdf_import_path(campaign, import)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Proposed pages (2)")
      expect(response.body).to include("Overview")
      expect(response.body).to include("Geography")
      expect(response.body).to include("Strahd")
      expect(response.body).to include("Apply import to campaign")
    end
  end

  describe "DELETE /campaigns/:id/pdf_imports/:id" do
    it "discards the import" do
      import = create(:pdf_import, campaign: campaign, user: user)
      expect {
        delete campaign_pdf_import_path(campaign, import)
      }.to change(campaign.pdf_imports, :count).by(-1)
    end
  end
end
