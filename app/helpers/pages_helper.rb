module PagesHelper
  def render_message(message)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})
    markdown.render(message).html_safe
  end
end
