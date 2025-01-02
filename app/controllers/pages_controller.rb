class PagesController < ApplicationController
  before_action :set_page, only: %i[ show edit update destroy ]
  before_action :set_user_and_campaigns
  before_action :set_campaign
  before_action :authorize_user

  # GET /pages or /pages.json
  def index
    @pages = Page.all
  end

  # GET /pages/1 or /pages/1.json
  def show
  end

  # GET /pages/new
  def new
    @page = Page.new
  end

  # GET /pages/1/edit
  def edit
  end

  # POST /pages or /pages.json
  def create
    @page = Page.new(page_params)

    if @page.save
      flash[:success] = "Page was successfully created."
      redirect_to campaign_page_path(@campaign, @page)
    else
      redirect_to campaign_pages_path, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /pages/1 or /pages/1.json
  def update
    if @page.update(page_params)
      flash[:success] = "Page was successfully updated"
      redirect_to campaign_page_path(@campaign, @page)
    else
      redirect_to campaign_page_path(@campaign, @page), status: :unprocessable_entity
    end
  end

  # DELETE /pages/1 or /pages/1.json
  def destroy
    @page.destroy!

    flash[:notice] = "Page was successfully destroyed"
    redirect_to campaign_pages_path, status: :see_other
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = Page.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def page_params
      params.expect(page: [ :title, :slug, :body, :parent_id, :campaign_id, :position ])
    end

    def set_user_and_campaigns
      @user = current_user

      if @user
        @campaigns = @user.campaigns
      else
        redirect_to login_path, alert: "Please log in" # Or any other logic to handle unauthenticated users
      end
    end

    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
      if @campaign.nil?
        redirect_to campaigns_path, alert: "Campaign not found."
      end
    end

    def authorize_user
      role = @campaign.roles.find_by(user: current_user)

      if role.nil? || !role.role_type.in?([ "gamemaster", "player" ])
        redirect_to root_path, alert: "You do not have access to this campaign."
      end
    end

end
