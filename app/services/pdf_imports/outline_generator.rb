module PdfImports
  class OutlineGenerator
    APPROX_CHARS_PER_TOKEN = 4
    MAX_INPUT_TOKENS = 180_000 # Sonnet 4.6 standard context, leave headroom for output.

    class TooLarge < StandardError; end

    def self.call(pdf_import, adapter:)
      new(pdf_import, adapter: adapter).call
    end

    def initialize(pdf_import, adapter:)
      @pdf_import = pdf_import
      @adapter = adapter
    end

    def call
      pdf_text = build_pdf_text
      ensure_size_fits!(pdf_text)

      payload = @adapter.call_tool(
        system_blocks: [
          { text: instructions, cache: false },
          { text: pdf_text, cache: true }
        ],
        messages: [
          { role: "user", content: "Produce the outline and entity list now using the submit_outline tool." }
        ],
        tool: tool_schema
      )

      validate_and_normalize(payload)
    end

    private

      def build_pdf_text
        @pdf_import.extracted_pages.each_with_index.map do |page_text, idx|
          "<page n=\"#{idx + 1}\">\n#{page_text}\n</page>"
        end.join("\n")
      end

      def ensure_size_fits!(text)
        approx_tokens = text.length / APPROX_CHARS_PER_TOKEN
        return if approx_tokens <= MAX_INPUT_TOKENS

        raise TooLarge,
              "PDF is approximately #{approx_tokens.to_fs(:delimited)} tokens, which exceeds the " \
              "#{MAX_INPUT_TOKENS.to_fs(:delimited)}-token limit. Try a shorter PDF for now."
      end

      def instructions
        existing_kinds = @pdf_import.campaign.entity_kinds.pluck(:name).sort.join(", ").presence || "(none)"

        <<~PROMPT
          You are ingesting a TTRPG sourcebook (campaign or setting) into a campaign organizer.
          Your job is to propose:
          1. A nested tree of wiki pages that mirrors the book's structure but is useful for play
             at the table -- group related material together, keep page granularity reasonable
             (typically 5-40 pages for a sourcebook; not one page per PDF page, not one giant
             page).
          2. A list of named entities (characters, locations, factions, items, organizations,
             creatures, deities, etc.) that should be tracked separately from the prose.

          Existing entity kinds in this campaign: #{existing_kinds}
          You may reuse those kinds or propose new lowercase singular kinds (e.g. "creature",
          "deity", "spell") when the existing list does not fit.

          Each page must reference the 1-indexed PDF pages it covers via source_pages, so the
          body-writing pass can quote the right material. Pages may overlap source ranges if
          content genuinely belongs in multiple places (e.g. a region's pantheon page might
          share source pages with the religion chapter).

          Use stable string tmp_id values like "p1", "p2", "e1" so children and entities can
          reference parents reliably.

          Call submit_outline once with the full proposal.
        PROMPT
      end

      def tool_schema
        {
          name: "submit_outline",
          description: "Submit the proposed page tree and entity list extracted from the sourcebook.",
          input_schema: {
            type: "object",
            properties: {
              pages: {
                type: "array",
                description: "Proposed wiki pages. List parents before children so the tree can be reconstructed in order.",
                items: {
                  type: "object",
                  properties: {
                    tmp_id: { type: "string", description: "Stable temporary id (e.g. p1) used for parent and entity references." },
                    title: { type: "string" },
                    parent_tmp_id: { type: [ "string", "null" ], description: "tmp_id of the parent page, or null for a top-level page." },
                    source_pages: { type: "array", items: { type: "integer" }, description: "1-indexed PDF page numbers covered by this page." },
                    summary: { type: "string", description: "One or two sentences describing what this page should contain. Used by the body-writing pass." }
                  },
                  required: %w[tmp_id title source_pages summary]
                }
              },
              entities: {
                type: "array",
                description: "Proposed entities to track separately from the prose.",
                items: {
                  type: "object",
                  properties: {
                    tmp_id: { type: "string" },
                    name: { type: "string" },
                    kind: { type: "string", description: "Lowercase singular kind, e.g. 'character', 'location', 'faction', 'creature'." },
                    summary: { type: "string", description: "One or two sentence description suitable for hover tooltips." }
                  },
                  required: %w[tmp_id name kind summary]
                }
              }
            },
            required: %w[pages entities]
          }
        }
      end

      def validate_and_normalize(payload)
        pages = Array(payload[:pages]).map { |p| p.slice(:tmp_id, :title, :parent_tmp_id, :source_pages, :summary) }
        entities = Array(payload[:entities]).map { |e| e.slice(:tmp_id, :name, :kind, :summary) }

        seen_page_ids = pages.map { |p| p[:tmp_id] }.to_set
        # Drop dangling parent references rather than fail outright.
        pages.each { |p| p[:parent_tmp_id] = nil unless p[:parent_tmp_id] && seen_page_ids.include?(p[:parent_tmp_id]) }

        entities.each { |e| e[:kind] = e[:kind].to_s.downcase.strip.presence || "other" }

        {
          pages: pages,
          entities: entities,
          entity_kinds: entities.map { |e| e[:kind] }.uniq
        }
      end
  end
end
