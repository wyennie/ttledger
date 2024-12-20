class FriendshipsController < ApplicationController
  def create
    @receiver = User.find(params[:receiver_id])
    
    if current_user != @receiver && !friendship_exists?(current_user, @receiver)
      @friendship = Friendship.create(sender: current_user, receiver: @receiver, status: 'pending')
      
      if @friendship.save
        redirect_to @receiver, notice: 'Friendship request sent.'
      else
        redirect_to @receiver, alert: 'Unable to send friendship request.'
      end
    else
      redirect_to @receiver, alert: 'You are already friends or cannot send a request to yourself.'
    end
  end

  def update
    @friendship = Friendship.find(params[:id])

    if @friendship.receiver == current_user
      if friendship_params[:status] == 'accepted'
        @friendship.update(status: 'accepted')
        redirect_to user_path(current_user), notice: 'Friendship accepted.'
      elsif friendship_params[:status] == 'denied'
        @friendship.update(status: 'denied')
        @friendship.destroy
        redirect_to user_path(current_user), notice: 'Friendship denied.'
      else
        redirect_to user_path(current_user), alert: 'Invalid action.'
      end
    else
      redirect_to user_path(current_user), alert: 'You cannot respond to this request.'
    end
  end
  
  private
  
  def friendship_exists?(user1, user2)
    Friendship.exists?(
      (Friendship.where(sender: user1, receiver: user2, status: 'accepted') +
      Friendship.where(sender: user2, receiver: user1, status: 'accepted')).uniq
    )
  end

  def friendship_params
    params.require(:friendship).permit(:status)
  end
end
