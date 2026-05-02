class ExpandDraftPageJob < ApplicationJob
  retry_on Anthropic::Errors::RateLimitError, wait: 30.seconds, attempts: 8

  def perform(pdf_import_id, page_tmp_id)
    import = PdfImport.find(pdf_import_id)
    return unless import.expanding?

    page = find_page(import, page_tmp_id)
    if page && page["body"].blank?
      adapter = LLMResolver.client_for(import.user).adapter
      body_html = PdfImports::BodyGenerator.call(import, page_tmp_id: page_tmp_id, adapter: adapter)
      store_body!(import, page_tmp_id, body_html)
    end

    chain_next!(import.reload)
  rescue ActiveRecord::RecordNotFound
    # Import was deleted mid-flight.
  rescue LLMResolver::QuotaExceeded
    import&.fail!("LLM quota exhausted while expanding pages.")
  rescue StandardError => e
    import&.fail!("Body pass failed for page #{page_tmp_id}: #{e.class}: #{e.message}")
    raise
  end

  private

    def find_page(import, page_tmp_id)
      Array(import.draft_payload&.dig("pages")).find { |p| p["tmp_id"].to_s == page_tmp_id.to_s }
    end

    def store_body!(import, page_tmp_id, body_html)
      import.with_lock do
        draft = import.draft_payload || {}
        draft["pages"] = Array(draft["pages"]).map do |p|
          p["tmp_id"].to_s == page_tmp_id.to_s ? p.merge("body" => body_html) : p
        end
        import.update!(draft_payload: draft)
      end
    end

    def chain_next!(import)
      return unless import.expanding?

      next_page = Array(import.draft_payload&.dig("pages")).find { |p| p["body"].blank? }
      if next_page
        self.class.perform_later(import.id, next_page["tmp_id"])
        return
      end

      # Wiki pages done -- start the entity bio chain (if any entities exist).
      next_entity = Array(import.draft_payload&.dig("entities")).find { |e| e["body"].blank? }
      if next_entity
        ExpandDraftEntityJob.perform_later(import.id, next_entity["tmp_id"])
      else
        import.update!(status: "ready_for_review")
      end
    end
end
