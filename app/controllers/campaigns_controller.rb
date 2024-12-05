class CampaignsController < ApplicationController
  before_action :logged_in?, only: [ :edit, :destroy ]


  def show
    @campaign = Campaign.find(params[:id])
    @campaigns = current_user.campaigns
    @user = current_user
  end

  def new
    @campaign = Campaign.new
    @campaigns = current_user.campaigns
    @user = current_user
  end

  def create
    @campaign = Campaign.new(campaign_params)
    @campaigns = current_user.campaigns
    @user = current_user

    if @campaign.save
      Role.create(user: current_user, campaign: @campaign, role_type: :gamemaster)
      flash[:success] = "Campaign created!"
      redirect_to @campaign
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
    @campaign = Campaign.find(params[:id])
    @campaigns = current_user.campaigns
    @user = current_user
  end

  def update
    @campaign = Campaign.find(params[:id])

    if @campaign.update(campaign_params)
      flash[:success] = "Campaign updated!"
      redirect_to @campaign
    else
      render "edit", status: :unpreccessable_entity
    end
  end

  def destroy
    campaign = Campaign.find(params[:id])
    campaign.roles.destroy_all
    campaign.characters.destroy_all
    campaign.destroy
    flash[:success] = "Campaign was successfully deleted."
    redirect_to user_path(current_user), status: :see_other
  rescue ActiveRecord::RecordNotFound
    render plain: "Campaign not found", status: :not_found
  end

  private

    def campaign_params
      params.require(:campaign).permit(:name, :description)
    end
end
