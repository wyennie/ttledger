module ApplicationHelper
  def render_markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML, hard_wrap: true)
    renderer.render(text).html_safe
  end
end
