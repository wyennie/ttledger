require 'rails_helper'

RSpec.describe Page, type: :model do
  it "has a valid factory" do
    page = create(:page)
    expect(page.title.presence).to be_truthy
  end

  describe "slugs" do
    it "creates a slug" do
      page = create(:page, title: "New Page Title")
      expect(page.slug).to match("new-page-title")
      page.update(title: "Another title")
      expect(page.slug).to match("another-title")
    end

    it "for untitled" do
      page = create(:page, title: nil)
      expect(page.slug).to be_truthy
    end
  end

  it "is a tree of ordered pages" do
    page1 = create(:page, title: "Page 1")
    expect(page1.position).to eq(1)
    page2 = create(:page, title: "Page 2")
    expect(page2.position).to eq(2)
    page3 = create(:page, title: "Page 3")
    expect(page3.position).to eq(3)
    pp [ page1.campaign.name, page2.campaign.name, page3.campaign.name ]

    page1_1 = create(:page, title: "Page1.1", parent: page1)
    expect(page1_1.position).to eq(1)
    page1_2 = create(:page, title: "Page1.2", parent: page1)
    expect(page1_2.position).to eq(2)
    page2_1 = create(:page, title: "Page2.1", parent: page2)
    expect(page2_1.position).to eq(1)
  end
end
