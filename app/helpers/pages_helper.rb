module PagesHelper
  PAGE_BODY_ATTRIBUTES = (
    Rails::Html::SafeListSanitizer.allowed_attributes.to_a +
    %w[data-mention data-entity-id data-entity-type class]
  ).uniq.freeze

  def sanitize_page_body(html)
    sanitize(html.to_s, attributes: PAGE_BODY_ATTRIBUTES)
  end
end
