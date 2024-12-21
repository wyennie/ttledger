class FriendshipsController < ApplicationController
  def create
    @receiver = User.find_by username: params[:username]

    if current_user != @receiver && !friendship_exists?(current_user, @receiver)
      @friendship = Friendship.create(sender: current_user, receiver: @receiver, status: "pending")

      if @friendship.save
        redirect_to current_user, notice: "Friendship request sent."
      else
        redirect_to current_user, alert: "Unable to send friendship request."
      end
    else
      redirect_to current_user, alert: "You are already friends or cannot send a request to yourself."
    end
  end

  def update
    @friendship = Friendship.find(params[:id])

    if @friendship.receiver == current_user
      if friendship_params[:status] == "accepted"
        @friendship.update(status: "accepted")
        redirect_to user_path(current_user), notice: "Friendship accepted."
      elsif friendship_params[:status] == "denied"
        @friendship.update(status: "denied")
        @friendship.destroy
        redirect_to user_path(current_user), notice: "Friendship denied."
      else
        redirect_to user_path(current_user), alert: "Invalid action."
      end
    else
      redirect_to user_path(current_user), alert: "You cannot respond to this request."
    end
  end

  private

  def friendship_exists?(user1, user2)
    is_accepted_sender = Friendship.where(sender: user1, receiver: user2, status: "accepted").size == 1
    is_accepted_receiver = Friendship.where(sender: user2, receiver: user1, status: "accepted").size == 1
    is_pending_sender = Friendship.where(sender: user1, receiver: user2, status: "accepted").size == 1
    is_pending_receiver = Friendship.where(sender: user2, receiver: user1, status: "accepted").size == 1

    is_accepted_sender || is_pending_receiver ||
    is_pending_sender  || is_pending_receiver
  end

  def friendship_params
    params.require(:friendship).permit(:status)
  end
end
