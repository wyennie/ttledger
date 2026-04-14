class ExtractPdfTextJob < ApplicationJob
  def perform(pdf_import_id)
    import = PdfImport.find(pdf_import_id)
    return unless import.pending?

    import.transition_to!("extracting")

    pages = nil
    import.pdf.blob.open do |tempfile|
      pages = PdfTextExtractor.call(tempfile.path)
    end

    if pages.blank? || pages.all?(&:blank?)
      import.fail!("Could not extract any text from the PDF.")
      return
    end

    import.transition_to!("outlining", extracted_pages: pages)
    # Next step (outline pass) will be enqueued by a follow-up commit.
  rescue ActiveRecord::RecordNotFound
    # Import was deleted; nothing to do.
  rescue PdfTextExtractor::ExtractionError => e
    import&.fail!(e.message)
    raise
  rescue StandardError => e
    import&.fail!("Unexpected error during text extraction: #{e.class}: #{e.message}")
    raise
  end
end
