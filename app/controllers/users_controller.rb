class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    @campaigns = @user.campaigns
    @characters = @user.characters.includes(:campaign)
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
    @user = User.find(params[:id])
    @campaigns = @user.campaigns
  end

  def update
    @user = User.find(params[:id])
      Rails.logger.info("User found: #{@user.inspect}")
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

    def user_params
      params.require(:user).permit(:username, :name, :email,
                                   :password, :password_confirmation,
                                   :confirmed_at)
    end
end
