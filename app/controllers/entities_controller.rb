class EntitiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_campaign
  before_action :authorize_user
  before_action :set_entity, only: %i[show edit update destroy]

  def index
    @entities = @campaign.entities.includes(:entity_kind).order(:name)
    @grouped = @entities.group_by { |e| e.entity_kind.name }.sort.to_h
  end

  def show
    redirect_to edit_campaign_entity_path(@campaign, @entity)
  end

  def new
    @entity = @campaign.entities.new
  end

  def create
    @entity = @campaign.entities.new(entity_params)
    if @entity.save
      redirect_to campaign_entities_path(@campaign), notice: "Entity created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @entity.update(entity_params)
      redirect_to campaign_entities_path(@campaign), notice: "Entity updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @entity.destroy
    redirect_to campaign_entities_path(@campaign), notice: "Entity deleted."
  end

  def suggestions
    query = params[:q].to_s.strip
    scope = @campaign.entities.includes(:entity_kind).order(:name).limit(10)
    scope = scope.where("name ILIKE ?", "%#{query}%") if query.present?
    render json: scope.map { |e|
      { id: e.id, name: e.name, kind: e.entity_kind.name, slug: e.slug }
    }
  end

  private

    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    end

    def set_entity
      @entity = @campaign.entities.friendly.find(params[:slug])
    end

    def authorize_user
      role = @campaign.roles.find_by(user: current_user)
      if role.nil?
        redirect_to root_path, alert: "You do not have access to this campaign."
      end
    end

    def entity_params
      params.require(:entity).permit(:name, :summary, :entity_kind_id, :bio_page_id)
    end
end
