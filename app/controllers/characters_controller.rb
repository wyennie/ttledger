class CharactersController < ApplicationController
  before_action :logged_in?, only: [ :create, :edit, :update, :destroy ]
  before_action :set_campaign
  before_action :set_character, only: [ :edit, :update, :destroy ]

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
    @character.build_character_derived_stat unless @character.character_derived_stat
    @character.build_character_stat unless @character.character_stat
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
      :name, :description, :occupation, :title, :character_class,
      :alignment, :speed, :level, :xp, :ac,
      character_stat_attributes: [
        :strength_current,     :strength_max,     :strength_modifier,
        :agility_current,      :agility_max,      :agility_modifier,
        :stamina_current,      :stamina_max,      :stamina_modifier,
        :personality_current,  :personality_max,  :personality_modifier,
        :intelligence_current, :intelligence_max, :intelligence_modifier,
        :luck_current,         :luck_max,         :luck_modifier
      ],
      character_derived_stat_attributes: [
        :initiative, :action_dice, :attack_dice, :crit_die, :crit_table,
        :fumble_die, :fumble_table, :reflex, :fortitude, :willpower,
        :hp, :max_hp
      ]
    )
  end
end
