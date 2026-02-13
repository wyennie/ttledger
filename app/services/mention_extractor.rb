class MentionExtractor
  MENTION_SELECTOR = "span[data-mention='entity'][data-entity-id]".freeze

  def initialize(mentionable)
    @mentionable = mentionable
  end

  def reindex!
    found_ids = extract_ids

    Mention.transaction do
      @mentionable.mentions.delete_all
      next if found_ids.empty?

      found_ids.each_with_index do |entity_id, idx|
        Mention.create!(
          entity_id: entity_id,
          mentionable: @mentionable,
          position: idx
        )
      end
    end

    @mentionable.association(:mentions).reset
  end

  private

    def extract_ids
      return [] if source_html.blank?

      doc = Nokogiri::HTML5.fragment(source_html)
      valid_ids = Set.new(@mentionable.campaign.entities.pluck(:id))

      doc.css(MENTION_SELECTOR).filter_map do |node|
        id = Integer(node["data-entity-id"], exception: false)
        id if id && valid_ids.include?(id)
      end
    end

    def source_html
      @mentionable.respond_to?(:body) ? @mentionable.body : @mentionable.try(:content)
    end
end
