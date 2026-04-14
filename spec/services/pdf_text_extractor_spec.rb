require 'rails_helper'

RSpec.describe PdfTextExtractor do
  describe ".call" do
    it "returns one entry per PDF page, split on form feeds" do
      pages = described_class.call(Rails.root.join("spec/fixtures/pdfs/two_pages.pdf"))
      expect(pages.size).to eq(2)
      expect(pages[0]).to include("Hello world")
      expect(pages[1]).to include("Second page")
    end

    it "raises ExtractionError when the file is not a PDF" do
      File.write("/tmp/not-a-pdf.txt", "hi")
      expect {
        described_class.call("/tmp/not-a-pdf.txt")
      }.to raise_error(PdfTextExtractor::ExtractionError)
    end
  end
end
