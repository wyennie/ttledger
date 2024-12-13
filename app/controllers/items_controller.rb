class ItemsController < ApplicationController
  before_action :set_character_and_campaign

  def create
    @item = @character.items.build(item_params)
    if @item.save
      redirect_to edit_campaign_character_path(@campaign, @character)
    else
      flash[:danger] = "Failed to create item."
      puts @item.errors.full_messages
      render "characters/edit"
    end
  end

  def edit
    @item = @character.items.find(params[:id])
  end

  def update
    @item = @character.items.find(params[:id])
    if @item.update(item_params)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("item-list", partial: "items/item_list", locals: { character: @character }) }
        format.html { redirect_to campaign_character_path(@campaign, @character), notice: "Item updated successfully." }
      end
    else
      flash.now[:alert] = "Failed to update item."
      render "characters/edit"
    end
  end

  def destroy
    @item = @character.items.find(params[:id])
    @item.destroy
    redirect_to edit_campaign_character_path(@campaign, @character)
  end

  private

  def set_character_and_campaign
    @user = current_user
    @campaign = Campaign.find(params[:campaign_id])
    @campaigns = current_user.campaigns
    @character = @campaign.characters.find(params[:character_id])
  end

  def item_params
    params.fetch(:item, {}).permit(:name, :description, :weight, :value, :count, :container_id, :item_type_id)
  end
end
