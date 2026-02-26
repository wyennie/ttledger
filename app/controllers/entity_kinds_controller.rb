class EntityKindsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign
  before_action :authorize_user
  before_action :set_sidebar_context

  def index
    @entity_kinds = @campaign.entity_kinds.includes(:entities).order(:name)
    @entity_kind = @campaign.entity_kinds.new
  end

  def create
    @entity_kind = @campaign.entity_kinds.new(entity_kind_params)
    if @entity_kind.save
      redirect_to campaign_entity_kinds_path(@campaign), notice: "Kind added."
    else
      @entity_kinds = @campaign.entity_kinds.includes(:entities).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def update
    @entity_kind = @campaign.entity_kinds.find(params[:id])
    if @entity_kind.update(entity_kind_params)
      redirect_to campaign_entity_kinds_path(@campaign), notice: "Kind renamed."
    else
      @entity_kinds = @campaign.entity_kinds.includes(:entities).order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @entity_kind = @campaign.entity_kinds.find(params[:id])
    if @entity_kind.entities.any?
      redirect_to campaign_entity_kinds_path(@campaign),
                  alert: "Cannot delete '#{@entity_kind.name}' — #{@entity_kind.entities.count} entities still use it. Reassign them first."
    elsif @entity_kind.destroy
      redirect_to campaign_entity_kinds_path(@campaign), notice: "Kind deleted."
    else
      redirect_to campaign_entity_kinds_path(@campaign), alert: "Could not delete kind."
    end
  end

  private

    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    end

    def set_sidebar_context
      @user = current_user
      @top_pages = @campaign.pages.top_level
    end

    def authorize_user
      role = @campaign.roles.find_by(user: current_user)
      if role.nil?
        redirect_to root_path, alert: "You do not have access to this campaign."
      end
    end

    def entity_kind_params
      params.require(:entity_kind).permit(:name)
    end
end
