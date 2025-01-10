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
    sse                               = SSE.new(response.stream, event: "message")
    client                            = OpenAI::Client.new(
        access_token: Rails.application.credentials.open_ai_api_key,
        log_errors: true
      )

    training_prompts = [
        "Do you know what tabletop roleplaying games are? Your job is to assist the game master",
        addPageContext
      ]

    messages = training_prompts.map do |prompt|
      { role: "user", content: prompt }
    end

    messages << { role: "user", content: params[:prompt] }

    begin
      client.chat(
        parameters: {
          model:    "gpt-4o-mini-2024-07-18",
          messages: messages,
          stream:   proc do |chunk|
            content = chunk.dig("choices", 0, "delta", "content")
            if content.nil?
              return
            end

            sse.write({
                        message: content
                      })
          end
        }
      )
    ensure
      sse.close
    end
  end

  def addPageContext
    page = Page.find_by(slug: params[:page_slug])
    body = ""
    if !!page.body
      body = page.body
              .gsub(/<\/ul>/, "")
              .gsub(/<ul>/, "\n")
              .gsub(/<\/li>/, "")
              .gsub(/<li>/, "\n- ")
              .gsub(/<\/?p>|<br\s*\/?>/, "\n")
              .gsub(/\n+/, "\n")
    end
    "Given the following information:\n" + body + "\n" + "Answer the following: \n"
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

  # PATCH/PUT /pages/1 or /pages/1.json
  def update
    respond_to do |format|
      if @page.update(page_params)
        format.turbo_stream
        format.html { redirect_to campaign_page_path(@campaign, @page) }
      else
        format.html { render :edit, status: :unprocessable_entity }
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
