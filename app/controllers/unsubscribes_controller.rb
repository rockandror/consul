class UnsubscribesController < ApplicationController
  before_action :set_user
  skip_authorization_check

  def edit
  end

  private

    def set_user
      @user = User.find_by_unsubscribe_hash(params[:unsubscribe_hash])
    end
end
