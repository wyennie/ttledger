class PagesController < ApplicationController
  include ActionController::Live
  before_action :set_page, only: %i[ show update destroy ]
  before_action :set_user_and_campaigns
  before_action :set_campaign
  before_action :authorize_user

  # GET /pages/1 or /pages/1.json
  def show
    @top_pages = @campaign.pages.top_level
    @chat = Chat.find_by(campaign_id: params[:campaign_id])
    @chats = @chat.messages
  end

  def clear_messages
    @page = Page.find_by(slug: params[:page_slug], campaign_id: params[:campaign_id])
    if @page
      @page.chat_messages.destroy_all
      # ActionCable.server.broadcast "chat_#{params[:campaign_id]}_#{params[:page_slug]}", { type: 'clear' }
    else
      flash[:error] = "Page not found"
      redirect_to campaign_pages_path(@campaign)
    end
  end

  def chat_messages
    page = Page.find_by(slug: params[:slug])
    @messages = page.chat_messages
    render json: @messages
  end


  # GET /pages or /pages.json
  def index
    @chat_message = []
    if (@page = @campaign.pages.top_level.first)
    else
      @page = @campaign.pages.create!
    end
    redirect_to campaign_page_path(@campaign, @page)
  end

  def create
    @page = @campaign.pages.new(create_page_params)
    @page.parent_id = params[:parent_id] if params[:parent_id]

    if @page.save
      redirect_to campaign_page_path(@campaign, @page)
    else
      render :new, status: :unprocessable_entity
      format.html { render :new, status: :unprocessable_entity }
    end
  end


  def update
    respond_to do |format|
      if @page.update(page_params)
        if @page.saved_change_to_title?
          redirect_to campaign_page_path(@campaign, @page)
        elsif @page.saved_change_to_body?
          format.turbo_stream
        end

          format.turbo_stream
      else
        format.turbo_stream
      end
    end
  end


  # DELETE /pages/1 or /pages/1.json
  def destroy
    destroy_children_recursively(@page)

    respond_to do |format|
      format.html { redirect_to campaign_pages_path }
    end
  end

  private

    def destroy_children_recursively(page)
      # Recursively destroy children first
      page.children.each do |child|
        destroy_children_recursively(child)
      end
      # Destroy the current page
      page.destroy
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_page
      @page = Page.find_by(slug: params[:slug], campaign_id: params[:campaign_id])
      if @page.nil?
        redirect_to campaign_pages_path
      end
    end

    # Only allow a list of trusted parameters through.
    def page_params
      params.require(:page).permit(:title, :body, :parent_id, :position)
    end

    def create_page_params
      params.permit(:page).permit(:title, :parent_id, :position)
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
