class TestMailer < ActionMailer::Base
  def hello(user, url)
    @user = user
    @url = url

    mail(
      subject: "Welcome to Tabletop Ledger",
      to: user.email,
      from: "sender@example.com",
      template_path: "user_mailer",
      template_name: "confirmation_email"
    )
  end
end
