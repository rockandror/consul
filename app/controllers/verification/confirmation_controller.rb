class Verification::ConfirmationController < ApplicationController
  before_action :authenticate_user!
  before_action :verify_lock
  authorize_resource

  def new
    @confirmation = Verification::Confirmation.new
  end

  def create
    @confirmation = Verification::Confirmation.new(confirmation_params.merge(user: current_user))
    if @confirmation.save
      # TODO: Mark current user as verified if all handlers returned successful responses
      redirect_to verified_user_path,
        notice: t("verification.confirmation.create.flash.success")
    else
      render :new
    end
  end

  private

    def confirmation_params
      params.require(:verification_confirmation).permit(Verification::Configuration.confirmation_fields)
    end
end