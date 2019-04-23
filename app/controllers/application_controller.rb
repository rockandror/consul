require "application_responder"

class ApplicationController < ActionController::Base
  include HasFilters
  include HasOrders
  include Analytics

  protect_from_forgery with: :exception

  before_action :authenticate_http_basic, if: :http_basic_auth_site?

  before_action :ensure_signup_complete
  before_action :set_locale
  before_action :track_email_campaign
  before_action :set_return_url
  before_action :set_fallbacks_to_all_available_locales

  check_authorization unless: :devise_controller?
  self.responder = ApplicationResponder

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html {
        if current_user && current_user.officing_voter?
          redirect_to new_officing_session_path
        else
          redirect_to main_app.root_url, alert: exception.message
        end
      }
      format.json { render json: {error: exception.message}, status: :forbidden }
    end
  end

  layout :set_layout
  respond_to :html
  helper_method :current_budget

  private

    def authenticate_http_basic
      authenticate_or_request_with_http_basic do |username, password|
        username == Rails.application.secrets.http_basic_username && password == Rails.application.secrets.http_basic_password
      end
    end

    def http_basic_auth_site?
      Rails.application.secrets.http_basic_auth
    end

    def verify_lock
      if current_user.locked?
        redirect_to account_path, alert: t('verification.alert.lock')
      end
    end

    def set_locale
      if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
        session[:locale] = params[:locale]
      end

      session[:locale] ||= I18n.default_locale

      locale = session[:locale]

      if current_user && current_user.locale != locale.to_s
        current_user.update(locale: locale)
      end

      I18n.locale = locale
      Globalize.locale = I18n.locale
    end

    def set_layout
      if devise_controller? && params[:landing]
        "landing"
      elsif devise_controller?
        "devise"
      else
        "application"
      end
    end

    def set_debate_votes(debates)
      @debate_votes = current_user ? current_user.debate_votes(debates) : {}
    end

    def set_proposal_votes(proposals)
      @proposal_votes = current_user ? current_user.proposal_votes(proposals) : {}
    end

    def set_spending_proposal_votes(spending_proposals)
      @spending_proposal_votes = current_user ? current_user.spending_proposal_votes(spending_proposals) : {}
    end

    def set_comment_flags(comments)
      @comment_flags = current_user ? current_user.comment_flags(comments) : {}
    end

    def ensure_signup_complete
      if user_signed_in? && !devise_controller? && current_user.registering_with_oauth
        redirect_to finish_signup_path
      end
    end

    def verify_resident!
      unless current_user.residence_verified?
        redirect_to new_residence_path, alert: t('verification.residence.alert.unconfirmed_residency')
      end
    end

    def verify_verified!
      if current_user.level_three_verified?
        redirect_to(account_path, notice: t('verification.redirect_notices.already_verified'))
      end
    end

    def track_email_campaign
      if params[:track_id]
        campaign = Campaign.where(track_id: params[:track_id]).first
        ahoy.track campaign.name if campaign.present?
      end

      if params[:track_id] == "172943750183759812"
        session[:track_signup] = true
      end
    end

    def set_return_url
      if !devise_controller? && controller_name != 'welcome' && is_navigational_format?
        store_location_for(:user, request.path)
      end
    end

    def set_default_budget_filter
      if @budget.try(:balloting?) || @budget.try(:publishing_prices?)
        params[:filter] ||= "selected"
      elsif @budget.try(:finished?)
        params[:filter] ||= "winners"
      end
    end

    def current_budget
      Budget.current
    end

    def set_fallbacks_to_all_available_locales
      Globalize.set_fallbacks_to_all_available_locales
    end
end
