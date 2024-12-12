class CharactersController < ApplicationController
  before_action :logged_in?, only: [:create, :edit, :update, :destroy]
  before_action :set_campaign
  before_action :set_character, only: [:edit, :update, :destroy]

  def create
    @character = @campaign.characters.new(character_params)
    @character.user = current_user

    if @character.save
      flash[:success] = "Character created!"

      redirect_to campaign_path(@campaign)
    else
      render @campaign, status: :unprocessable_entity 
    end
  end

  def edit
    @character = @campaign.characters.find(params[:id])
    @user = current_user
    @campaigns = current_user.campaigns
  end

  def update
    @character = @campaign.characters.find(params[:id])
    @character.user = current_user
    if @character.update(character_params)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @character.user = current_user
    @character.destroy
    flash[:success] = "Character was successfully deleted." 
    redirect_to campaign_path(@campaign) 
  end

  private

  def set_campaign
    @campaign = Campaign.find(params[:campaign_id])
  end

  def set_character
    @character = @campaign.characters.find(params[:id])
  end

  def character_params
    params.require(:character).permit(:name)
  end
end
