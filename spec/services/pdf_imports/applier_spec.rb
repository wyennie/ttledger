require 'rails_helper'

RSpec.describe PdfImports::Applier do
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:campaign) { create(:campaign) }
  let(:draft_payload) do
    {
      "pages" => [
        { "tmp_id" => "p1", "title" => "Overview", "parent_tmp_id" => nil, "source_pages" => [ 1 ], "summary" => "intro",
          "body" => "<p>Welcome to <span data-mention=\"entity\" data-entity-tmp-id=\"e1\">@Strahd</span>'s land.</p>" },
        { "tmp_id" => "p2", "title" => "Geography", "parent_tmp_id" => "p1", "source_pages" => [ 2 ], "summary" => "map",
          "body" => "<p>Mountains.</p>" }
      ],
      "entities" => [
        { "tmp_id" => "e1", "name" => "Strahd", "kind" => "character", "summary" => "Vampire lord." },
        { "tmp_id" => "e2", "name" => "Ireena", "kind" => "creature", "summary" => "Mysterious figure." }
      ]
    }
  end

  let(:import) do
    create(:pdf_import,
           campaign: campaign,
           user: user,
           status: "ready_for_review",
           draft_payload: draft_payload)
  end

  it "creates new entity kinds beyond the campaign defaults" do
    expect {
      described_class.call(import)
    }.to change { campaign.entity_kinds.count }.by(1)
    expect(campaign.entity_kinds.pluck(:name)).to include("creature")
  end

  it "creates entities under the right kinds" do
    described_class.call(import)
    strahd = campaign.entities.find_by(name: "Strahd")
    expect(strahd.entity_kind.name).to eq("character")
    expect(strahd.summary).to eq("Vampire lord.")
  end

  it "creates the page tree with parents wired up" do
    described_class.call(import)
    overview = campaign.pages.find_by(title: "Overview")
    geography = campaign.pages.find_by(title: "Geography")
    expect(overview.parent).to be_nil
    expect(geography.parent).to eq(overview)
  end

  it "rewrites entity-mention placeholders to real entity ids and triggers mention indexing" do
    described_class.call(import)
    strahd = campaign.entities.find_by(name: "Strahd")
    overview = campaign.pages.find_by(title: "Overview")

    expect(overview.body).to include("data-entity-id=\"#{strahd.id}\"")
    expect(overview.body).not_to include("data-entity-tmp-id")
    expect(overview.mentioned_entities).to include(strahd)
  end

  it "reuses an existing entity by case-insensitive name rather than failing on uniqueness" do
    kind = campaign.entity_kinds.find_by(name: "character")
    existing = campaign.entities.create!(name: "strahd", entity_kind: kind, summary: "old")

    described_class.call(import)

    expect(campaign.entities.where("LOWER(name) = ?", "strahd").count).to eq(1)
    expect(existing.reload.summary).to eq("old") # not overwritten in v1
  end

  it "marks the import applied" do
    described_class.call(import)
    expect(import.reload.status).to eq("applied")
  end

  it "rolls everything back if any record fails" do
    # Entity name max length is 120 -- this overshoots and triggers a validation error.
    import.draft_payload["entities"] << {
      "tmp_id" => "ex",
      "name" => "x" * 200,
      "kind" => "character",
      "summary" => "too long"
    }
    import.save!

    expect {
      expect {
        described_class.call(import)
      }.to raise_error(ActiveRecord::RecordInvalid)
    }.not_to(change { campaign.pages.count })
    expect(campaign.entities.count).to eq(0)
    expect(import.reload.status).to eq("ready_for_review")
  end

  it "refuses to apply when the import is not ready_for_review" do
    import.update!(status: "expanding")
    expect {
      described_class.call(import)
    }.to raise_error(described_class::NotReady)
  end
end
