class RemoteTranslationsController < ApplicationController
  skip_authorization_check
  respond_to :html, :js

  before_action :set_remote_translations, only: :create

  def create
    @remote_translations.each do |remote_translation|
      RemoteTranslation.create(remote_translation) if translations_not_enqueued?(remote_translation)
    end
    redirect_to request.referer, notice: t('remote_translations.create.enqueue_remote_translation')
  end

  private

  def remote_translations_params
    params.permit(:remote_translations)
  end

  def set_remote_translations
    @remote_translations = ActiveSupport::JSON.decode(remote_translations_params["remote_translations"])
  end

  def translations_not_enqueued?(remote_translation)
    RemoteTranslation.where(remote_translatable_id: remote_translation["remote_translatable_id"],
                            remote_translatable_type: remote_translation["remote_translatable_type"],
                            to: remote_translation["to"],
                            error_message: nil).empty?
  end
end
