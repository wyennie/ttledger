class PagesController < ApplicationController
  include ActionController::Live
  before_action :set_page, only: %i[ show update destroy ]
  before_action :set_user_and_campaigns
  before_action :set_campaign
  before_action :authorize_user

  # GET /pages/1 or /pages/1.json
  def show
    @top_pages = @campaign.pages.top_level
    @chat_message = []
  end

  def chat_response
    response.headers["Content-Type"]  = "text/event-stream"
    response.headers["Last-Modified"] = Time.now.httpdate
    sse = SSE.new(response.stream, event: "message")
    chat_service = ChatService.new()
    page_context = chat_service.add_page_context(params[:page_slug])
    prompts = [
      "Do you know what tabletop roleplaying games are? Your job is to assist the game master",
      page_context
    ]

    begin
        chat_service.generate_response(prompts, params[:prompt]) do |chunk|
        content = chunk.dig("choices", 0, "delta", "content")
        sse.write({ message: content }) if content.present?
      end
    rescue => e
      logger.error "ChatService Error: #{e.message}"
      sse.write({ error: "An error occurred while generating the response." })
    ensure
      sse.close
    end
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
    else
      format.turbo_stream
    end
  end
end


  # DELETE /pages/1 or /pages/1.json
  def destroy
    @page.destroy

    respond_to do |format|
      format.html { redirect_to campaign_pages_path }
    end
  end

  private
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
