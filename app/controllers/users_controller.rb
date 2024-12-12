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
      log_in @user
      flash[:success] = "Welcome to Character Craft!"
      redirect_to @user
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
    if @user.update(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render "edit", status: :unprocessable_entity
    end
  end

  private

    def user_params
      params.require(:user).permit(:username, :name, :email,
                                   :password, :password_confirmation)
    end
end
