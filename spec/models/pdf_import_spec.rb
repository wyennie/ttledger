require 'rails_helper'

RSpec.describe PdfImport, type: :model do
  let(:campaign) { create(:campaign) }

  it "has a valid factory" do
    expect(create(:pdf_import, campaign: campaign)).to be_persisted
  end

  it "rejects a non-pdf attachment on create" do
    import = build(:pdf_import, campaign: campaign)
    import.pdf.detach
    import.pdf.attach(
      io: StringIO.new("not a pdf"),
      filename: "evil.txt",
      content_type: "text/plain"
    )
    expect(import).not_to be_valid
    expect(import.errors[:pdf]).to be_present
  end

  it "requires an attached pdf on create" do
    import = build(:pdf_import, campaign: campaign)
    import.pdf.detach
    expect(import).not_to be_valid
    expect(import.errors[:pdf]).to be_present
  end

  it "rejects an unknown status" do
    import = build(:pdf_import, campaign: campaign, status: "bogus")
    expect(import).not_to be_valid
  end

  describe "#fail!" do
    it "sets status to failed and records the error message" do
      import = create(:pdf_import, campaign: campaign)
      import.fail!("boom")
      expect(import.reload).to be_failed
      expect(import.error_message).to eq("boom")
    end
  end
end
