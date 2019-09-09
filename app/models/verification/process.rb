class Verification::Process
  include ActiveModel::Model
  attr_accessor :fields, :handlers, :responses, :user

  validates :user, presence: true
  validate :handlers

  def initialize(attributes = {})
    define_fields_accessors
    define_fields_validations

    @responses = {}
    @fields = fields_by_name
    @handlers = Verification::Configuration.active_handlers

    super
  end

  def save
    verify_handlers if valid?
  end

  # Returs true if any of the active handlers requires a confirmation step
  def requires_confirmation?
    Verification::Handler.descendants.select{|k| @handlers.include?(k.id)}.
      any?(&:requires_confirmation?)
  end

  private

    def verify_handlers
      @handlers.each do |handler|
        handler_instance = Verification::Configuration.available_handlers[handler].
          new(fields_for_handler(handler))

        @responses[handler] = handler_instance.verify
      end
    end

    # Validates each verification field through defined handlers and copy errors
    # to process fields
    def handlers
      return if @handlers.none?

      @handlers.each do |handler|
        handler_instance = Verification::Configuration.available_handlers[handler].
          new(fields_for_handler(handler))

        unless handler_instance.valid?
          handler_instance.errors.each do |field, error|
            errors.add field, error
          end
        end
      end
    end

    # Defines attribute accessors for all verification fields
    def define_fields_accessors
      Verification::Field.all.pluck(:name).each do |attr|
        define_singleton_method attr do
          instance_variable_get "@#{attr}"
        end

        define_singleton_method "#{attr}=" do |arg|
          instance_variable_set "@#{attr}", arg
        end
      end
    end

    # Return {} with fields by name
    def fields_by_name
      Verification::Field.all.each_with_object({}) do |field, hash|
        hash[field.name] = field
      end
    end

    # Return {} of fields for given handler by handler name
    def fields_for_handler(handler)
      params = {}
      @fields.each do |field_name, field|
        params[field_name] = send(field_name) if field.handlers&.include?(handler)
      end
      params[:user] = user
      params.symbolize_keys!
    end

    # Define self validations from existing verification fields
    def define_fields_validations
      define_presence_validations
    end

    def define_presence_validations
      self.singleton_class.class_eval do
        Verification::Field.required.each do |field|
          validates field.name, presence: true
        end
      end
    end
end