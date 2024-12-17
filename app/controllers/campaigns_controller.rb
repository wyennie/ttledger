class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_and_campaigns
  before_action :set_campaign, only: [ :destroy, :update, :edit, :show ]

  def show
  end

  def authenticate_user!
    redirect_to login_path unless logged_in?
  end

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      Role.create(user: current_user, campaign: @campaign, role_type: :gamemaster)
      flash[:success] = "Campaign created!"
      redirect_to @campaign
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @campaign.update(campaign_params)
      flash[:success] = "Campaign updated!"
      redirect_to @campaign
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.roles.destroy_all
    @campaign.characters.destroy_all
    @campaign.destroy
    flash[:success] = "Campaign was successfully deleted."
    redirect_to user_path(current_user), status: :see_other
  rescue ActiveRecord::RecordNotFound
    render plain: "Campaign not found", status: :not_found
  end

  private

    def campaign_params
      params.require(:campaign).permit(:name, :description)
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
      if @campaign.nil?
        redirect_to campaigns_path, alert: "Campaign not found."
      end
    end

    def set_user_and_campaigns
      @user = current_user

      if @user
        @campaigns = @user.campaigns
      else
        redirect_to login_path, alert: "Please log in" # Or any other logic to handle unauthenticated users
      end
   end
end
