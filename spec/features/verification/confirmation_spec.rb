require "rails_helper"

describe "Verification confirmation" do
  let!(:phone_field)       { create(:verification_field, name: "phone", label: "Phone", position: 3) }
  let(:user)               { create(:user) }

  before do
    create(:verification_handler_field_assignment, verification_field: phone_field, handler: "sms")
    Setting["feature.custom_verification_process"] = true
    login_as(user)
  end

  describe "New" do
    scenario "Shows fields for all required confirmation codes" do
      Class.new(Verification::Handler) do
        register_as :my_handler
        requires_confirmation true
      end
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "my_handler")
      visit new_verification_confirmation_path

      expect(page).to have_field "verification_confirmation_sms_confirmation_code"
      expect(page).to have_field "verification_confirmation_my_handler_confirmation_code"
    end
  end

  describe "Create" do
    scenario "Shows presence error validations" do
      Class.new(Verification::Handler) do
        register_as :my_handler
        requires_confirmation true
      end
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "my_handler")
      visit new_verification_confirmation_path
      click_button "Confirm"

      expect(page).to have_content "can't be blank", count: 2
    end

    scenario "Shows code confirmations error validations" do
      Class.new(Verification::Handler) do
        register_as :my_handler
        requires_confirmation true

        def confirm(attributes)
          Verification::Handlers::Response.new false,
                                               "My handler confirtmation code does not match",
                                               attributes,
                                               nil
        end
      end
      user.update(sms_confirmation_code: "ABCD")
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "my_handler")
      visit new_verification_confirmation_path
      fill_in "Sms confirmation code", with: "ABCE"
      fill_in "My handler confirmation code", with: "QWER"
      click_button "Confirm"

      expect(page).to have_content "Confirmation code does not match"
      expect(page).to have_content "My handler confirtmation code does not match"
    end

    scenario "when confirmation codes are introduced successfully should redirect user to account page" do
      Class.new(Verification::Handler) do
        register_as :my_handler
        requires_confirmation true

        def confirm(attributes)
          if attributes[:my_handler_confirmation_code] == "QWER"
            Verification::Handlers::Response.new true, "Success!", (attributes), nil
          else
            Verification::Handlers::Response.new(false,
                                                 "My handler confirtmation code does not match",
                                                 (attributes),
                                                 nil)
          end
        end
      end
      user.update(sms_confirmation_code: "ABCD")
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "my_handler")
      visit new_verification_confirmation_path
      fill_in "Sms confirmation code", with: "ABCD"
      fill_in "My handler confirmation code", with: "QWER"
      click_button "Confirm"

      expect(page).to have_content "Accout verification process was done successfully!"
    end
  end
end