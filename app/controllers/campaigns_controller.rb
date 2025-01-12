class CampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_and_campaigns
  before_action :set_campaign, only: [ :invite_user, :accept_invitation, :destroy, :update, :edit, :show ]
  before_action :authorize_user, only: [ :show ]
  before_action :authorize_gamemaster, only: [ :invite_user, :edit, :update ]

  def invite_user
    user = User.find_by(username: params[:username])
    if user
      invitation = @campaign.campaign_invitations.create(sender: current_user, receiver: user)
      if invitation.persisted?
        flash[:success] = "Invitation sent to #{user.username}."
      else
        flash[:danger] = invitation.errors.full_messages.to_sentence
      end
    else
      flash[:danger] = "User not found"
    end
    redirect_to @campaign
  end

  def accept_invitation
    invitation = CampaignInvitation.find_by(id: params[:invitation_id], receiver: current_user, status: "pending")
    if invitation
      Role.create(user: current_user, campaign: @campaign, role_type: :player)
      invitation.update(status: :accepted)
      flash[:success] = "You have joined the campaign as a player!"
    else
      flash[:danger] = "Invalid or expired invitaion."
    end
    redirect_to @campaign
  end

  def show
    @players = @campaign.users.joins(:roles).where(roles: { role_type: "player" }).distinct
  end

  def authenticate_user!
    redirect_to login_path unless logged_in?
  end

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new(campaign_params)

    if @campaign.save
      Role.create(user: current_user, campaign: @campaign, role_type: :gamemaster)
      flash[:success] = "Campaign created!"
      redirect_to campaign_pages_path(@campaign)
    else
      render "new", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @campaign.update(campaign_params)
      flash[:success] = "Campaign updated!"
      redirect_to user_path(@user)
    else
      render "edit", status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.roles.destroy_all
    @campaign.characters.destroy_all
    @campaign.pages.destroy_all
    @campaign.destroy
    flash[:success] = "Campaign was successfully deleted."
    redirect_to user_path(current_user), status: :see_other
  rescue ActiveRecord::RecordNotFound
    render plain: "Campaign not found", status: :not_found
  end

  private

    def authorize_gamemaster
      unless @campaign.roles.exists?(user: current_user, role_type: :gamemaster)
        flash[:danger] = "Only the gamemaster can invite users."
        redirect_to root_path
      end
    end

    def campaign_params
      params.require(:campaign).permit(:name, :description)
    end

    def set_campaign
      @campaign = Campaign.find(params[:id])
      if @campaign.nil?
        redirect_to campaigns_path, alert: "Campaign not found."
      end
    end

    def set_user_and_campaigns
      @user = current_user

      if @user
        @campaigns = @user.campaigns
      else
        redirect_to login_path, alert: "Please log in" # Or any other logic to handle unauthenticated users
      end
    end

    def authorize_user
      role = @campaign.roles.find_by(user: current_user)

      if role.nil? || !role.role_type.in?([ "gamemaster", "player" ])
        redirect_to root_path, alert: "You do not have access to this campaign."
      end
    end
end
