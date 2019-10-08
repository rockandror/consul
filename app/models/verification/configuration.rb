class Verification::Configuration

  class << self
    def available_handlers
      Verification::Handler.descendants.each_with_object({}) do |handler, hash|
        hash[handler.id] = handler
      end
    end

    def active_handlers_ids
      all_settings = Setting.all.group_by { |setting| setting.type }
      all_settings["custom_verification_process"].map {|setting| setting.key.rpartition(".").last if setting.enabled?}
    end

    def active_handlers
      Verification::Handler::FieldAssignment.where(handler: active_handlers_ids).pluck(:handler).uniq
    end

    def required_confirmation_handlers
      condition = lambda { |id, handler| handler.requires_confirmation? && active_handlers.include?(id) }

      available_handlers.select(&condition)
    end

    def confirmation_fields
      handlers = available_handlers.select{ |id, handler| active_handlers.include?(id) && handler.requires_confirmation? }

      handlers.keys.each_with_object([]) do |handler, fields|
        handler_name = handler.downcase.underscore

        fields << "#{handler_name}_confirmation_code"
      end
    end
  end
end
Dir[Rails.root.join("app/models/verification/handlers/*.rb")].each {|file| require_dependency file }
