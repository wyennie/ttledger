require 'rails_helper'

RSpec.describe "User sign up", type: :system do

  it "Shows and error message when submitting password and password confirmation that do not match" do
    visit signup_path
    fill_in "Name", with: "John Johnson"
    fill_in "Email", with: "user1@example.com"
    fill_in "Password", with: "foobar"
    fill_in "Confirmation", with: "blablabla"
    click_on "Create account"
 
    expect(page.has_content?("Password confirmation doesn't match Password")).to eq true
  end

  it "Shows an error message when the name is left blank" do
    visit signup_path
    fill_in "Name", with: "     "
    fill_in "Email", with: "user1@example.com"
    fill_in "Password", with: "foobar"
    fill_in "Confirmation", with: "foobar"
    click_on "Create account"
    
    expect(page.has_content?("Name can't be blank")).to eq true
  end

  it "Shows an error message if the email is already in use" do
    @user = User.new(name: "Example User", email: "user@example.com",
                            password: "foobar", password_confirmation: "foobar")
    @user.save
    visit signup_path
    fill_in "Name", with: "John Johnson"
    fill_in "Email", with: "user@example.com"
    fill_in "Password", with: "foobar"
    fill_in "Confirmation", with: "foobar"
    click_on "Create account"
    
    expect(page.has_content?("Email has already been taken")).to eq true
  end
end
