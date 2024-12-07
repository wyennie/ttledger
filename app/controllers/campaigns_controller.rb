class CampaignsController < ApplicationController
  before_action :logged_in?, only: [ :edit, :destroy ]
  before_action :set_user_and_campaigns

  def show
    @campaign = Campaign.find(params[:id])
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
    @campaign = Campaign.find(params[:id])
  end

  def update
    @campaign = Campaign.find(params[:id])

    if @campaign.update(campaign_params)
      flash[:success] = "Campaign updated!"
      redirect_to @campaign
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    @campaign = Campaign.find(params[:id])
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

    def set_user_and_campaigns
      @campaigns = current_user.campaigns
      @user = current_user
   end
end
