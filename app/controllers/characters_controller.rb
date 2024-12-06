class CharactersController < ApplicationController
  before_action :set_campaign, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_character, only: [ :edit, :update, :destroy ]

  def show
  end

  def new
    @character = Character.new
    @campaigns = current_user.campaigns
    @user = current_user
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

    def set_campaign
      @campaign = Campaign.find(params[:campaign_id])
    end
end
