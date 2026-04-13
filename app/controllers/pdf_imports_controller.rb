class PdfImportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_and_campaigns
  before_action :set_campaign
  before_action :authorize_gamemaster
  before_action :set_pdf_import, only: %i[show update destroy apply]

  def new
    @pdf_import = @campaign.pdf_imports.new
  end

  def create
    @pdf_import = @campaign.pdf_imports.new(create_params.merge(user: current_user))
    @pdf_import.original_filename = create_params[:pdf]&.original_filename

    if @pdf_import.save
      ExtractPdfTextJob.perform_later(@pdf_import.id) if defined?(ExtractPdfTextJob)
      redirect_to campaign_pdf_import_path(@campaign, @pdf_import)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @pdf_import.destroy
    redirect_to campaign_path(@campaign), notice: "Import discarded."
  end

  def apply
    head :not_implemented
  end

  def update
    head :not_implemented
  end

  private

    def set_pdf_import
      @pdf_import = @campaign.pdf_imports.find(params[:id])
    end

    def create_params
      params.require(:pdf_import).permit(:pdf)
    end

    def set_user_and_campaigns
      @user = current_user
      @campaigns = @user&.campaigns
      redirect_to login_path, alert: "Please log in" unless @user
    end

    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    rescue ActiveRecord::RecordNotFound
      redirect_to campaigns_path, alert: "Campaign not found."
    end

    def authorize_gamemaster
      unless @campaign.roles.exists?(user: current_user, role_type: :gamemaster)
        redirect_to campaign_path(@campaign), alert: "Only the gamemaster can import PDFs."
      end
    end
end
