require_dependency Rails.root.join("app", "models", "verification", "handler.rb").to_s

class Verification::Configuration
  class << self
    def available_handlers
      Verification::Handler.descendants.each_with_object({}) do |handler, hash|
        hash[handler.id] = handler
      end
    end

    def active_handlers
      Verification::Field::Assignment.where(handler: active_handlers_ids).pluck(:handler).uniq
    end

    def required_confirmation_handlers
      condition = lambda { |id, handler| handler.requires_confirmation? && active_handlers.include?(id) }

      available_handlers.select(&condition)
    end

    def confirmation_fields
      required_confirmation_handlers.keys.each_with_object([]) do |handler, fields|
        handler_name = handler.downcase.underscore

        fields << "#{handler_name}_confirmation_code"
      end
    end

    def verification_fields(handler = nil)
      fields = Verification::Field.all
      return fields if handler.blank?

      fields.select { |field| field.handlers.include?(handler) }
    end

    private

      def active_handlers_ids
        ids = available_handlers.keys

        all_settings = Setting.all.group_by { |setting| setting.type }
        all_settings["custom_verification_process"].
          select { |setting| setting.enabled? && ids.include?(setting.key.rpartition(".").last) }.
          collect { |setting| setting.key.rpartition(".").last }
      end
  end
end
