require 'rails_helper'

RSpec.describe ExtractPdfTextJob, type: :job do
  let(:campaign) { create(:campaign) }
  let(:user) { create(:user, confirmed_at: Time.current) }
  let(:import) do
    create(:pdf_import, campaign: campaign, user: user).tap do |i|
      i.pdf.detach
      i.pdf.attach(
        io: File.open(Rails.root.join("spec/fixtures/pdfs/two_pages.pdf")),
        filename: "two_pages.pdf",
        content_type: "application/pdf"
      )
    end
  end

  it "extracts pages from the attached PDF and advances status to outlining" do
    described_class.perform_now(import.id)
    import.reload
    expect(import.status).to eq("outlining")
    expect(import.extracted_pages).to be_an(Array)
    expect(import.extracted_pages.size).to eq(2)
    expect(import.extracted_pages[0]).to include("Hello world")
  end

  it "marks the import failed when extraction errors" do
    allow(PdfTextExtractor).to receive(:call).and_raise(PdfTextExtractor::ExtractionError, "boom")
    expect {
      described_class.perform_now(import.id)
    }.to raise_error(PdfTextExtractor::ExtractionError)
    expect(import.reload).to be_failed
    expect(import.error_message).to eq("boom")
  end

  it "skips work when the import has already advanced past pending" do
    import.update!(status: "outlining", extracted_pages: [ "pre-existing" ])
    described_class.perform_now(import.id)
    expect(import.reload.extracted_pages).to eq([ "pre-existing" ])
  end
end
