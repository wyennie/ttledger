module PdfImports
  class Applier
    class NotReady < StandardError; end

    def self.call(pdf_import)
      new(pdf_import).call
    end

    def initialize(pdf_import)
      @pdf_import = pdf_import
    end

    def call
      raise NotReady, "Import is not ready for review" unless @pdf_import.ready_for_review?

      ActiveRecord::Base.transaction do
        ensure_entity_kinds!
        entity_by_tmp = create_entities!
        create_pages!(entity_by_tmp)
        attach_entity_bio_pages!(entity_by_tmp)
        @pdf_import.update!(status: "applied", error_message: nil)
      end
    end

    private

      def campaign
        @campaign ||= @pdf_import.campaign
      end

      def draft
        @draft ||= @pdf_import.draft_payload || {}
      end

      def draft_pages
        Array(draft["pages"])
      end

      def draft_entities
        Array(draft["entities"])
      end

      def ensure_entity_kinds!
        wanted = draft_entities.map { |e| e["kind"].to_s.downcase.strip }.reject(&:blank?).uniq
        existing = campaign.entity_kinds.pluck(:name).map(&:downcase).to_set
        (wanted - existing.to_a).each do |kind_name|
          campaign.entity_kinds.create!(name: kind_name)
        end
      end

      def create_entities!
        entity_kinds_by_name = campaign.entity_kinds.index_by { |k| k.name.downcase }
        entity_by_tmp = {}

        draft_entities.each do |draft_entity|
          name = draft_entity["name"].to_s.strip
          next if name.blank?

          kind_name = draft_entity["kind"].to_s.downcase.strip.presence || "other"
          kind = entity_kinds_by_name[kind_name] || entity_kinds_by_name["other"] || campaign.entity_kinds.first

          existing = campaign.entities.where("LOWER(name) = ?", name.downcase).first
          entity = existing || campaign.entities.create!(
            name: name,
            entity_kind: kind,
            summary: draft_entity["summary"]
          )
          entity_by_tmp[draft_entity["tmp_id"]] = entity
        end

        entity_by_tmp
      end

      def create_pages!(entity_by_tmp)
        page_by_tmp = {}

        ordered_pages.each do |draft_page|
          parent = page_by_tmp[draft_page["parent_tmp_id"]]
          body = rewrite_mentions(draft_page["body"].to_s, entity_by_tmp)

          page = campaign.pages.create!(
            title: draft_page["title"],
            body: body,
            parent: parent
          )
          page_by_tmp[draft_page["tmp_id"]] = page
        end
      end

      # Topologically sort: parents before children. We do this even though the
      # outline pass usually emits parents first, because we drop dangling
      # parent_tmp_ids during validation and want a stable result regardless.
      def ordered_pages
        remaining = draft_pages.dup
        ordered = []
        emitted = Set.new

        guard = remaining.size + 1
        while remaining.any? && guard.positive?
          guard -= 1
          progress = false
          remaining.reject! do |p|
            parent = p["parent_tmp_id"]
            if parent.nil? || emitted.include?(parent)
              ordered << p
              emitted << p["tmp_id"]
              progress = true
              true
            else
              false
            end
          end
          break unless progress
        end

        # If a cycle ever sneaks in, treat the leftovers as top-level so we
        # don't drop content silently.
        remaining.each do |p|
          ordered << p.merge("parent_tmp_id" => nil)
        end

        ordered
      end

      # Materializes generated entity bios as Page records linked from
      # entities.bio_page_id. Skips entities without a body and entities that
      # already have a bio (existing campaign entities reused by name).
      def attach_entity_bio_pages!(entity_by_tmp)
        draft_entities.each do |draft_entity|
          body_html = draft_entity["body"].to_s
          next if body_html.blank?

          entity = entity_by_tmp[draft_entity["tmp_id"]]
          next if entity.nil? || entity.bio_page_id.present?

          bio_page = campaign.pages.create!(
            title: entity.name,
            body: rewrite_mentions(body_html, entity_by_tmp),
            parent: nil
          )
          entity.update!(bio_page: bio_page)
        end
      end

      def rewrite_mentions(html, entity_by_tmp)
        return "" if html.blank?

        doc = Nokogiri::HTML5.fragment(html)
        doc.css("span[data-mention='entity'][data-entity-tmp-id]").each do |node|
          tmp = node["data-entity-tmp-id"]
          entity = entity_by_tmp[tmp]
          if entity
            node.delete("data-entity-tmp-id")
            node["data-entity-id"] = entity.id.to_s
            node["data-entity-label"] = entity.name
            node["data-entity-type"] = entity.entity_kind.name
          else
            # Unknown tmp_id: strip the mention but keep the visible text.
            node.replace(node.children)
          end
        end
        doc.to_html
      end
  end
end
