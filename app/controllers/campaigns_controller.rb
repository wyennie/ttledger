class CampaignsController < ApplicationController
  before_action :logged_in?

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

  def show
    @campaign = Campaign.find(params[:id])
  end

  private
    def campaign_params
      params.require(:campaign).permit(:name, :description)
    end
end
