require "open3"

class PdfTextExtractor
  class ExtractionError < StandardError; end

  PAGE_DELIMITER = "\f"

  def self.call(path)
    new(path).call
  end

  def initialize(path)
    @path = path.to_s
  end

  def call
    stdout, stderr, status = Open3.capture3(
      "pdftotext", "-layout", "-enc", "UTF-8", @path, "-"
    )

    unless status.success?
      raise ExtractionError, "pdftotext failed: #{stderr.presence || "unknown error"}"
    end

    split_pages(stdout)
  end

  private

    def split_pages(text)
      pages = text.split(PAGE_DELIMITER, -1)
      pages.pop if pages.last == ""
      pages.map { |p| normalize(p) }
    end

    def normalize(page_text)
      page_text.gsub(/\r\n?/, "\n").strip
    end
end
