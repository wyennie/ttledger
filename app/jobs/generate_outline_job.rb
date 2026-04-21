class GenerateOutlineJob < ApplicationJob
  def perform(pdf_import_id)
    import = PdfImport.find(pdf_import_id)
    return unless import.outlining?

    adapter = adapter_for(import)
    payload = PdfImports::OutlineGenerator.call(import, adapter: adapter)

    if payload[:pages].empty?
      import.fail!("Outline pass produced no pages.")
      return
    end

    import.transition_to!("ready_for_review", draft_payload: payload)
    # Per-page body generation comes in the next commit; for now the user can
    # at least see the proposed structure.
  rescue ActiveRecord::RecordNotFound
    # Import deleted mid-flight.
  rescue PdfImports::OutlineGenerator::TooLarge => e
    import&.fail!(e.message)
  rescue LLMResolver::QuotaExceeded
    import&.fail!("LLM quota exhausted. Add an Anthropic API key in your account settings to continue.")
  rescue AnthropicAdapter::ToolCallMissing => e
    import&.fail!("Model did not return a structured outline. #{e.message}")
    raise
  rescue StandardError => e
    import&.fail!("Outline pass failed: #{e.class}: #{e.message}")
    raise
  end

  private

    def adapter_for(import)
      LLMResolver.client_for(import.user).adapter
    end
end
