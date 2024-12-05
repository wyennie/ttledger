require "rails_helper"

RSpec.describe "User log in", type: :system do
  let!(:user) { FactoryBot.create(:user) }

  it "shows an error message for only one page reload when user logs in with invalid credentials" do
    visit login_path
    fill_in "Email",    with: "testuser@example.com"
    fill_in "Password", with: "incorrect password"
    click_on "Log in"
    visit login_path

    expect(page.has_content?("Invalid email/password combination")).to eq false
  end

  it "user is redirected home when they log in" do
    visit login_path
    fill_in "Email",    with: "testuser@example.com"
    fill_in "Password", with: "password"
    click_on "Log in"

    expect(page).to have_current_path(users_path + "/#{user.id}")
  end
end
