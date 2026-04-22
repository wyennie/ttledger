module PdfImports
  class BodyGenerator
    def self.call(pdf_import, page_tmp_id:, adapter:)
      new(pdf_import, page_tmp_id: page_tmp_id, adapter: adapter).call
    end

    def initialize(pdf_import, page_tmp_id:, adapter:)
      @pdf_import = pdf_import
      @page_tmp_id = page_tmp_id
      @adapter = adapter
    end

    def call
      page = find_page!
      payload = @adapter.call_tool(
        system_blocks: [
          # Same first block as the outline pass -- shared cache prefix.
          { text: pdf_text_block, cache: true },
          { text: instructions(page), cache: false }
        ],
        messages: [
          { role: "user", content: "Write the HTML body for the page now using the submit_body tool." }
        ],
        tool: tool_schema
      )

      payload[:html_body].to_s
    end

    private

      def find_page!
        draft = @pdf_import.draft_payload || {}
        Array(draft["pages"] || draft[:pages]).find { |p| (p["tmp_id"] || p[:tmp_id]).to_s == @page_tmp_id.to_s } ||
          raise(ArgumentError, "Draft page #{@page_tmp_id.inspect} not found")
      end

      def pdf_text_block
        @pdf_import.extracted_pages.each_with_index.map do |page_text, idx|
          "<page n=\"#{idx + 1}\">\n#{page_text}\n</page>"
        end.join("\n")
      end

      def instructions(page)
        draft = @pdf_import.draft_payload
        all_pages = Array(draft["pages"] || draft[:pages])
        all_entities = Array(draft["entities"] || draft[:entities])

        outline_summary = all_pages.map do |p|
          parent = p["parent_tmp_id"] || p[:parent_tmp_id]
          indent = parent ? "  " : ""
          tmp = p["tmp_id"] || p[:tmp_id]
          title = p["title"] || p[:title]
          "#{indent}- [#{tmp}] #{title}"
        end.join("\n")

        entity_summary = all_entities.map do |e|
          "- [#{e['tmp_id'] || e[:tmp_id]}] #{e['name'] || e[:name]} (#{e['kind'] || e[:kind]}) -- #{e['summary'] || e[:summary]}"
        end.join("\n")

        title = page["title"] || page[:title]
        summary = page["summary"] || page[:summary]
        source_pages = Array(page["source_pages"] || page[:source_pages])

        <<~PROMPT
          Write the HTML body for the wiki page titled "#{title}".

          Page sketch (from the outline pass): #{summary}
          PDF pages to draw from: #{source_pages.join(", ")} (1-indexed; reference the <page n="..."> blocks in the document above).

          Output requirements:
          - Use TipTap-compatible HTML only. Allowed tags: h2, h3, h4, p, strong, em, u, code, blockquote, ul, ol, li, hr, table, thead, tbody, tr, th, td. Do not include <h1> (the title is rendered by the wiki itself).
          - When referring to a tracked entity, wrap its name in
            <span data-mention="entity" data-entity-tmp-id="ENTITY_TMP_ID">@Entity Name</span>
            using the tmp_id from the entity list below. Do not invent new entities here -- only use entities that already appear in the list. The "@" prefix in the visible text is required.
          - Do not include any <script>, <style>, or external resource tags.
          - Aim for prose that's useful for a GM at the table: faithful to the source, well-organized, with section headings and lists where helpful.
          - Do not output the page title at the top of the body; start with the first section.

          Page outline (for cross-references; you may only @-mention entities, not other pages):
          #{outline_summary}

          Entity list available for @-mentions:
          #{entity_summary.presence || "(none)"}

          Call submit_body with the finished HTML.
        PROMPT
      end

      def tool_schema
        {
          name: "submit_body",
          description: "Submit the HTML body for the requested wiki page.",
          input_schema: {
            type: "object",
            properties: {
              html_body: {
                type: "string",
                description: "TipTap-compatible HTML body for the page. Use entity-mention spans for any tracked entity references."
              }
            },
            required: %w[html_body]
          }
        }
      end
  end
end
