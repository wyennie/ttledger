require "rails_helper"

RSpec.describe "User log out", type: :system do
  it "redirects to root" do
    user = FactoryBot.create(:user, email: "wryennie@example.com",
                                    password: "foobar",
                                    password_confirmation: "foobar")
    visit login_path
    fill_in "Email", with: "wryennie@example.com"
    fill_in "Password", with: "foobar"
    click_on "Log in"

    click_on "Log out"
    expect(page).to have_current_path(root_path)
  end
end
