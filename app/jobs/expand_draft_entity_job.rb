class ExpandDraftEntityJob < ApplicationJob
  retry_on Anthropic::Errors::RateLimitError, wait: 30.seconds, attempts: 8

  def perform(pdf_import_id, entity_tmp_id)
    import = PdfImport.find(pdf_import_id)
    return unless import.expanding?

    entity = find_entity(import, entity_tmp_id)
    if entity && entity["body"].blank?
      adapter   = LLMResolver.client_for(import.user).adapter
      body_html = PdfImports::EntityBodyGenerator.call(import, entity_tmp_id: entity_tmp_id, adapter: adapter)
      store_body!(import, entity_tmp_id, body_html)
    end

    chain_next!(import.reload)
  rescue ActiveRecord::RecordNotFound
    # Import was deleted mid-flight.
  rescue LLMResolver::QuotaExceeded
    import&.fail!("LLM quota exhausted while expanding entity bios.")
  rescue StandardError => e
    import&.fail!("Entity body pass failed for #{entity_tmp_id}: #{e.class}: #{e.message}")
    raise
  end

  private

    def find_entity(import, entity_tmp_id)
      Array(import.draft_payload&.dig("entities")).find { |e| e["tmp_id"].to_s == entity_tmp_id.to_s }
    end

    def store_body!(import, entity_tmp_id, body_html)
      import.with_lock do
        draft = import.draft_payload || {}
        draft["entities"] = Array(draft["entities"]).map do |e|
          e["tmp_id"].to_s == entity_tmp_id.to_s ? e.merge("body" => body_html) : e
        end
        import.update!(draft_payload: draft)
      end
    end

    def chain_next!(import)
      return unless import.expanding?

      next_entity = Array(import.draft_payload&.dig("entities")).find { |e| e["body"].blank? }
      if next_entity
        self.class.perform_later(import.id, next_entity["tmp_id"])
      else
        import.update!(status: "ready_for_review")
      end
    end
end
