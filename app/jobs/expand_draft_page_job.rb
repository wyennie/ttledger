class ExpandDraftPageJob < ApplicationJob
  def perform(pdf_import_id, page_tmp_id)
    import = PdfImport.find(pdf_import_id)
    return unless import.expanding?

    adapter = LLMResolver.client_for(import.user).adapter
    body_html = PdfImports::BodyGenerator.call(import, page_tmp_id: page_tmp_id, adapter: adapter)

    import.with_lock do
      draft = import.draft_payload || {}
      pages = Array(draft["pages"]).map do |p|
        if p["tmp_id"].to_s == page_tmp_id.to_s
          p.merge("body" => body_html)
        else
          p
        end
      end
      draft["pages"] = pages
      import.update!(draft_payload: draft)

      if pages.all? { |p| p["body"].is_a?(String) && !p["body"].empty? }
        import.update!(status: "ready_for_review")
      end
    end
  rescue ActiveRecord::RecordNotFound
    # Import was deleted mid-flight.
  rescue LLMResolver::QuotaExceeded
    import&.fail!("LLM quota exhausted while expanding pages.")
  rescue StandardError => e
    import&.fail!("Body pass failed for page #{page_tmp_id}: #{e.class}: #{e.message}")
    raise
  end
end
