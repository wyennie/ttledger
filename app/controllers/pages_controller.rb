class PagesController < ApplicationController
  include ActionController::Live
  before_action :set_page, only: %i[ show update destroy ]
  before_action :set_user_and_campaigns
  before_action :set_campaign
  before_action :authorize_user

  # GET /pages/1 or /pages/1.json
  def show
    @top_pages = @campaign.pages.top_level
  end

  def clear_messages
    @page = Page.find_by(slug: params[:page_slug], campaign_id: params[:campaign_id])

    if @page
      @page.chat_messages.destroy_all
      redirect_to campaign_page_path(@campaign, @page)
    else
      flash[:error] = "Page not found"
      redirect_to campaign_pages_path(@campaign)
    end
  end

  def chat_messages
    page = Page.find_by(slug: params[:slug])
    @messages = ChatMessage.where(page_id: page.id).order(:created_at)
    render json: @messages
  end



def chat_response
  begin
    logger.info "Setting response headers..."
    response.headers["Content-Type"]  = "text/event-stream"
    logger.info "Response headers set: #{response.headers}"

    logger.info "Initializing SSE and ChatService..."
    sse = SSE.new(response.stream,retry: 300, event: "message")
    chat_service = ChatService.new

    logger.info "Adding page context for page slug: #{params[:page_slug]}"
    page_context = chat_service.add_page_context(params[:page_slug])
    logger.debug "Page context: #{page_context}"

    logger.info "Fetching page by slug: #{params[:page_slug]}"
    page = Page.find_by(slug: params[:page_slug])
    if page.nil?
      logger.error "Page not found for slug: #{params[:page_slug]}"
      sse.write({ error: "Page not found." })
      return
    end

    logger.info "Fetching chat messages for the page..."
    messages = page.chat_messages
    logger.debug "Chat messages: #{messages.map(&:content)}"

    prompts = [
      "Do you know what tabletop roleplaying games are? Your job is to assist the game master",
      page_context
    ]

    logger.info "Adding chat messages to prompts..."
    messages.each do |message|
      logger.debug "Adding message to prompts: #{message.content}"
      prompts << message.content
    end

    logger.info "Generating chat response with prompts: #{prompts}"
    chat_service.generate_response(prompts, params[:prompt], params[:page_slug], params[:campaign_id], current_user) do |chunk|
      content = chunk.dig("choices", 0, "delta", "content")
      if content.present?
        logger.debug "Received content chunk: #{content}"
        sse.write({ message: content })
      else
        logger.debug "No content in the current chunk."
      end
    end
  rescue => e
    logger.error "ChatService Error: #{e.message}\n#{e.backtrace.join("\n")}"
    sse.write({ error: "An error occurred while generating the response." })
  ensure
    logger.info "Closing SSE stream..."
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

          format.turbo_stream
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
