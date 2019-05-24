include RemoteAvailableLocales
module RemoteTranslationsHelper

  def display_remote_translation_info?(remote_translations, locale)
    locales = RemoteAvailableLocales.get_available_locales
    locale = RemoteAvailableLocales.parse_locale(locale)
    remote_translations.present? && locales.include?(locale.to_s)
  end

  def display_remote_translation_button?(remote_translations)
    remote_translations.none? do |remote_translation|
      RemoteTranslation.remote_translation_enqueued?(remote_translation)
    end
  end
end
