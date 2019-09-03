class Verification::Handlers::Sms < Verification::Handler
  register_as :sms
  requires_confirmation true

  attr_accessor :user, :confirmation_code

  validates :phone, presence: true
  validates :phone, format: { with: /\A[\d \+]+\z/ }
  validate :unique_phone

  def verify
    if valid?
      update_user_phone_information
      send_sms
      Lock.increase_tries(user)
      Verification::Handlers::Response.new true, I18n.t("verification_handler_success"), { phone: phone }, nil
    else
      Verification::Handlers::Response.new false, I18n.t("verification_handler_error"), { phone: phone }, nil
    end
  end

  def update_user_phone_information
    user.update(unconfirmed_phone: phone, sms_confirmation_code: generate_confirmation_code)
  end

  def send_sms
    SMSApi.new.sms_deliver(user.unconfirmed_phone, user.sms_confirmation_code)
  end

  def verified?
    user.sms_confirmation_code == confirmation_code
  end

  private

    def unique_phone
      errors.add(:phone, :taken) if User.where(confirmed_phone: phone).any?
    end

    def generate_confirmation_code
      rand.to_s[2..5]
    end
end
