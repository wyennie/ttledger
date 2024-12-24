class CharactersController < ApplicationController
  before_action :logged_in?, only: [ :create, :edit, :update, :destroy ]
  before_action :set_campaign
  before_action :set_character, only: [ :edit, :update, :destroy ]
  before_action :authorize_user!, only: [ :edit, :update, :destroy ]

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
      render json: { message: "Saved successfully" }, status: :ok
    else
      render json: { errors: @character.errors.full_messages }, status: :unprocessable_entity
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
      params.require(:character).permit(
        :name, :description, :occupation, :title, :character_class, :alignment,
        :speed, :level, :xp, :ac, :background, :notes, :short_term_goals,
        :medium_term_goals, :long_term_goals, :languages, :lucky_sign, :initiative,
        :action_dice, :attack_bonus, :crit_die, :crit_table, :fumble_die, :reflex,
        :fortitude, :willpower, :current_hp, :max_hp, :current_strength, :max_strength,
        :current_agility, :max_agility, :current_stamina, :max_stamina,
        :current_personality, :max_personality, :current_intelligence,
        :max_intelligence, :current_luck, :max_luck
      )
    end

    def authorize_user!
      unless current_user == @character.user
        flash[:danger] = "You are not authorized to access this page."
        redirect_to @campaign
      end
    end
end
