module PdfImports
  class EntityBodyGenerator
    def self.call(pdf_import, entity_tmp_id:, adapter:)
      new(pdf_import, entity_tmp_id: entity_tmp_id, adapter: adapter).call
    end

    def initialize(pdf_import, entity_tmp_id:, adapter:)
      @pdf_import = pdf_import
      @entity_tmp_id = entity_tmp_id
      @adapter = adapter
    end

    def call
      entity = find_entity!
      payload = @adapter.call_tool(
        system_blocks: [
          # Same first block as the outline + page bodies -- shared cache prefix.
          { text: pdf_text_block, cache: true },
          { text: instructions(entity), cache: false }
        ],
        messages: [
          { role: "user", content: "Write the entity bio now using the submit_body tool." }
        ],
        tool: tool_schema,
        model: AnthropicAdapter::BODY_MODEL
      )

      payload[:html_body].to_s
    end

    private

      def find_entity!
        draft = @pdf_import.draft_payload || {}
        Array(draft["entities"] || draft[:entities]).find { |e| (e["tmp_id"] || e[:tmp_id]).to_s == @entity_tmp_id.to_s } ||
          raise(ArgumentError, "Draft entity #{@entity_tmp_id.inspect} not found")
      end

      def pdf_text_block
        @pdf_import.extracted_pages.each_with_index.map do |page_text, idx|
          "<page n=\"#{idx + 1}\">\n#{page_text}\n</page>"
        end.join("\n")
      end

      def instructions(entity)
        all_entities = Array(@pdf_import.draft_payload["entities"])

        siblings = all_entities
          .reject { |e| e["tmp_id"] == @entity_tmp_id }
          .map { |e| "- [#{e['tmp_id']}] #{e['name']} (#{e['kind']})" }
          .join("\n")

        <<~PROMPT
          Write a wiki bio page for the entity below. The bio must be drawn entirely from
          what the source PDF says about this entity -- do not invent details, do not pad.
          If the PDF only mentions the entity briefly, the bio should be brief.

          Entity name: #{entity['name']}
          Kind:        #{entity['kind']}
          Sketch:      #{entity['summary']}

          Output requirements:
          - Use TipTap-compatible HTML only. Allowed tags: h2, h3, h4, p, strong, em, u,
            code, blockquote, ul, ol, li, hr, table, thead, tbody, tr, th, td. Do not
            include <h1> -- the page title is rendered by the wiki itself.
          - Do not start with the entity's name as a heading; jump straight into the
            content.
          - Use h2/h3 for sections like "Background", "Appearance", "Role in the
            Adventure", "Related Locations", whatever the source actually supports.
            Skip sections you do not have material for.
          - When referring to a different tracked entity, wrap its name in
            <span data-mention="entity" data-entity-tmp-id="ENTITY_TMP_ID">@Entity Name</span>
            using a tmp_id from the list below. Do not invent new entities here.
          - Do not include <script>, <style>, or external resource tags.

          Other tracked entities you may @-mention:
          #{siblings.presence || "(none)"}

          Call submit_body with the finished HTML.
        PROMPT
      end

      def tool_schema
        {
          name: "submit_body",
          description: "Submit the HTML bio for the requested entity.",
          input_schema: {
            type: "object",
            properties: {
              html_body: {
                type: "string",
                description: "TipTap-compatible HTML bio for the entity. Use entity-mention spans for any references to other tracked entities."
              }
            },
            required: %w[html_body]
          }
        }
      end
  end
end
