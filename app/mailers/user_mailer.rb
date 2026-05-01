class UserMailer < ApplicationMailer
  default from: "noreply@willyennie.dev"

  def confirmation_email(user)
    @user = user
    @url = confirm_email_url(token: @user.confirmation_token)
    mail(to: @user.email, subject: "Email Confirmation")
  end
end
