class PdfImport < ApplicationRecord
  STATUSES = %w[pending extracting outlining expanding ready_for_review applied failed].freeze

  belongs_to :campaign
  belongs_to :user

  has_one_attached :pdf

  validates :status, inclusion: { in: STATUSES }
  validates :pdf, presence: { message: "must be attached" }, on: :create
  validate  :pdf_must_be_pdf, on: :create

  STATUSES.each do |s|
    define_method("#{s}?") { status == s }
  end

  def transition_to!(new_status, **attrs)
    update!(status: new_status, **attrs)
  end

  def fail!(message)
    update!(status: "failed", error_message: message.to_s.truncate(2000))
  end

  private

    def pdf_must_be_pdf
      return unless pdf.attached?

      unless pdf.content_type == "application/pdf" || pdf.filename.to_s.downcase.end_with?(".pdf")
        errors.add(:pdf, "must be a PDF file")
      end
    end
end
