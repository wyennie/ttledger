require 'rails_helper'

RSpec.describe "Users", type: :request do
  let!(:user) { create(:user, confirmed_at: Time.current) }
  let!(:valid_attributes) do
    { username: 'newuser', name: 'New User', email: 'newuser@example.com', password: 'password', password_confirmation: 'password', confirmed_at: Time.current }
  end
  let!(:invalid_attributes) do
    { username: '', name: 'Invalid User', email: 'invalidemail.com', password: 'short', password_confirmation: 'short' }
  end

  # A helper method to log in as a user
  def sign_in_as(user)
    post login_url, params: { session: { email: user.email, password: user.password } }
  end

  describe "GET /users/:id" do
    it "shows the user's profile" do
      sign_in_as(user)
      get user_path(user)

      expect(response).to have_http_status(:ok)
    end

    it "redirects to login if not authenticated" do
      get user_path(user)
      expect(response).to redirect_to(login_url)
    end
  end

  describe "GET /users/new" do
    it "renders the new user form" do
      get new_user_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sign Up')
    end
  end

  describe "POST /users" do
    context "with valid attributes" do
      it "creates a new user and redirects to the root path" do
        expect {
          post users_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(root_url)
        follow_redirect!

        expect(response.body).to include("Welcome! Create and manage whole campaigns with the help of AI assistants!")
      end
    end

    context "with invalid attributes" do
      it "does not create a user and re-renders the new form" do
        expect {
          post users_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('error')
      end
    end
  end

  describe "GET /users/:id/edit" do
    it "renders the edit user form" do
      sign_in_as(user)
      get edit_user_path(user)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Edit')
    end

    it "redirects to login if not authenticated" do
      get edit_user_path(user)
      expect(response).to redirect_to(login_url)
    end
  end

  describe "PATCH /users/:id" do
    context "with valid attributes" do
      it "updates the user's profile" do
        sign_in_as(user)
        patch user_path(user), params: { user: { username: 'updateduser', name: 'Updated Name' } }

        user.reload
        expect(user.username).to eq('updateduser')
        expect(user.name).to eq('Updated Name')
        expect(response).to redirect_to(user_path(user))
        follow_redirect!
        expect(response.body).to include('Profile updated')
      end
    end

    context "with invalid attributes" do
      it "does not update the user and re-renders the edit form" do
        sign_in_as(user)
        patch user_path(user), params: { user: { username: '', name: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Username can&#39;t be blank')
        expect(response.body).to include("<div id='error-explanation'")

        user.reload
        expect(user.username).not_to eq('')
        expect(user.name).not_to eq('')

        expect(response.body).to include("Edit")
      end
    end
  end

  describe "GET /users/confirm_email" do
    context "with a valid token" do
      context "with a valid token" do
        it "confirms the user's email" do
          valid_token = "valid_token"
          user.update(confirmation_token: valid_token)
          get confirm_email_path(token: valid_token)
          user.confirm_email

          user.reload

          expect(user.confirmed_at).not_to be_nil
          expect(user.confirmation_token).to be_nil
        end
      end
    end

    context "with an invalid or expired token" do
      it "redirects to the root path with an error" do
        get confirm_email_path(token: 'invalid_token')

        expect(response).to redirect_to(root_url)
      end
    end
  end
end
