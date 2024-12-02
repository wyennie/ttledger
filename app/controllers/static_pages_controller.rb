class StaticPagesController < ApplicationController
  before_action :redirect_if_logged_in

  def home
  end

  def about
  end

  private

    def redirect_if_logged_in
      if logged_in?
        redirect_to current_user
      end
    end
end
