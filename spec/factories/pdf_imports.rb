FactoryBot.define do
  factory :pdf_import do
    campaign { Campaign.first || create(:campaign) }
    user     { User.first || create(:user) }
    status { "pending" }
    original_filename { "sourcebook.pdf" }

    after(:build) do |import|
      next if import.pdf.attached?

      import.pdf.attach(
        io: StringIO.new("%PDF-1.4\n% fake pdf for tests\n"),
        filename: import.original_filename || "test.pdf",
        content_type: "application/pdf"
      )
    end
  end
end
