require "rails_helper"

RSpec.describe "User log in", type: :system do
  it "shows an error message for only one page reload when user logs in with invalid credentials" do
    visit login_path
    fill_in "Email", with: "wryennie@example.com"
    fill_in "Password", with: "incorrect password"
    click_on "Log in"
    visit login_path

    expect(page.has_content?("Invalid email/password combination")).to eq false
  end

  it "user is redirected home when they log in" do
    user = User.create!(
      name: "Will Yennie",
      email: "wryennie@example.com",
      password: "foobar",
      password_confirmation: "foobar"
    )
    visit login_path
    fill_in "Email", with: "wryennie@example.com"
    fill_in "Password", with: "foobar"
    click_on "Log in"

    expect(page).to have_current_path(users_path + "/#{user.id}")
  end
end

