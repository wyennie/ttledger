
require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:user_params) { { username: "newuser", name: "New User", email: "newuser@example.com", password: "password", password_confirmation: "password" } }

  describe 'GET #show' do
    subject { get :show, params: { id: user.id } }

    context 'when user exists' do
      it 'responds with a 200 status code' do
        subject
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'GET #new' do
    subject { get :new }

    it 'responds with a 200 status code' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { user: user_params } }

    context 'when user is valid' do
      it 'creates a new user' do
        expect { subject }.to change(User, :count).by(1)
      end

      it 'redirects to the user\'s show page' do
        subject
        expect(response).to redirect_to(user_path(User.last))
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:success]).to eq('Welcome to Character Craft!')
      end
    end

    context 'when user is invalid' do
      let(:invalid_user_params) { user_params.merge(email: "invalid_email") }

      subject { post :create, params: { user: invalid_user_params } }

      it 'does not create a new user' do
        expect { subject }.not_to change(User, :count)
      end

      it 'responds with unprocessable_entity status' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET #edit' do
    subject { get :edit, params: { id: user.id } }

    context 'when user exists' do
      it 'responds with a 200 status code' do
        subject
        expect(response).to have_http_status(:ok)
      end

      it 'loads the user\'s campaigns' do
        campaigns = create_list(:campaign, 3, users: [ user ])
      end
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, params: { id: user.id, user: user_params } }

    context 'when user is valid' do
      it 'updates the user' do
        subject
        user.reload
        expect(user.username).to eq(user_params[:username])
      end

      it 'redirects to the user\'s show page' do
        subject
        expect(response).to redirect_to(user_path(user))
      end

      it 'sets a success flash message' do
        subject
        expect(flash[:success]).to eq('Profile updated')
      end
    end

    context 'when user is invalid' do
      let(:invalid_user_params) { user_params.merge(email: "invalid_email") }

      subject { patch :update, params: { id: user.id, user: invalid_user_params } }

      it 'does not update the user' do
        subject
        user.reload
        expect(user.email).not_to eq("invalid_email")
      end

      it 'responds with unprocessable_entity status' do
        subject
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
