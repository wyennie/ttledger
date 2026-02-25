require 'rails_helper'

RSpec.describe MentionExtractor do
  let(:campaign) { create(:campaign) }
  let(:aria) { create(:entity, campaign: campaign, name: "Aria") }
  let(:bren) { create(:entity, campaign: campaign, name: "Bren") }
  let(:page) { create(:page, campaign: campaign) }

  def mention_span(entity, type: "character", label: nil)
    label ||= entity.name
    %(<span data-mention="entity" data-entity-id="#{entity.id}" data-entity-type="#{type}" data-entity-label="#{label}">@#{label}</span>)
  end

  it "indexes a single mention from page body via after_commit" do
    page.update!(body: "<p>Hello #{mention_span(aria)}.</p>")
    expect(page.mentions.pluck(:entity_id)).to eq([ aria.id ])
  end

  it "preserves position order across multiple mentions" do
    page.update!(body: "<p>#{mention_span(bren)} then #{mention_span(aria)} then #{mention_span(bren)}</p>")
    rows = page.mentions.order(:position).pluck(:entity_id)
    expect(rows).to eq([ bren.id, aria.id, bren.id ])
  end

  it "drops mentions of entities from other campaigns" do
    other_campaign = create(:campaign)
    foreign = create(:entity, campaign: other_campaign, name: "Outsider")
    page.update!(body: "<p>#{mention_span(aria)} #{mention_span(foreign)}</p>")
    expect(page.mentions.pluck(:entity_id)).to eq([ aria.id ])
  end

  it "drops malformed entity ids" do
    bad = %(<span data-mention="entity" data-entity-id="not-a-number">@?</span>)
    page.update!(body: "<p>#{mention_span(aria)} #{bad}</p>")
    expect(page.mentions.pluck(:entity_id)).to eq([ aria.id ])
  end

  it "is idempotent across repeated saves of the same body" do
    body = "<p>#{mention_span(aria)}</p>"
    page.update!(body: body)
    page.update!(body: body + " ")
    page.update!(body: body + " ")
    expect(page.mentions.count).to eq(1)
  end

  it "removes mentions when the body no longer references them" do
    page.update!(body: "<p>#{mention_span(aria)}</p>")
    expect(page.mentions.count).to eq(1)
    page.update!(body: "<p>plain text now</p>")
    expect(page.mentions.count).to eq(0)
  end

  it "skips reindexing when only the title changes" do
    page.update!(body: "<p>#{mention_span(aria)}</p>")
    expect(page.mentions.count).to eq(1)

    expect(MentionExtractor).not_to receive(:new)
    page.update!(title: "Renamed")
  end
end
