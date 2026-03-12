module PagesHelper
  PAGE_BODY_TAGS = (
    Rails::Html::SafeListSanitizer.allowed_tags.to_a +
    %w[table thead tbody tfoot tr th td colgroup col input label]
  ).uniq.freeze

  PAGE_BODY_ATTRIBUTES = (
    Rails::Html::SafeListSanitizer.allowed_attributes.to_a +
    %w[
      data-mention data-entity-id data-entity-type data-entity-label
      data-type data-checked
      colspan rowspan colwidth
      type checked disabled
      class
    ]
  ).uniq.freeze

  def sanitize_page_body(html)
    sanitize(html.to_s, tags: PAGE_BODY_TAGS, attributes: PAGE_BODY_ATTRIBUTES)
  end
end
