class UsersController < ApplicationController
  before_action :authenticate_user!, except: [ :new, :create, :confirm_email ]
  before_action :set_user, only: [ :show, :edit, :update ]
  before_action :authorize_user!, only: [ :show, :edit, :update ]

  def show
    # Fetch all Friendships related to the current_user (both sent and received)
    @friendships = Friendship.where("sender_id = ? OR receiver_id = ?", current_user.id, current_user.id)

    @user = User.find(params[:id])
    @sent_requests = @user.sent_friend_requests.where(status: 'pending')
    @received_requests = @user.received_friend_requests.where(status: 'pending')
    @campaigns = @user.campaigns
    @characters = @user.characters.includes(:campaign)

    @pending_friendships = @friendships.where(status: 'pending')
    @accepted_friendships = @friendships.where(status: 'accepted')
    @denied_friendships = @friendships.where(status: 'denied')
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_email
      flash[:info] = "Please check your email to confirm your account."
      redirect_to root_url
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
    @campaigns = @user.campaigns
  end

  def update
    @campaigns = @user.campaigns
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def confirm_email
    user = User.find_by(confirmation_token: params[:token])
    if user && !user.confirmed_at
      user.confirm_email
      flash[:success] = "Your email has been confirmed!"
      redirect_to login_url
    else
      flash[:danger] = "Invalid or expired confirmation link."
      redirect_to root_url
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:username, :name, :email,
                                   :password, :password_confirmation,
                                   :confirmed_at)
    end

    def authorize_user!
      unless current_user == @user
        flash[:danger] = "You are not authorized to access this page."
        redirect_to root_url
      end
    end
end
