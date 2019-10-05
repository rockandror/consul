require "rails_helper"

describe "Verification process" do

  let!(:name_field)        { create(:verification_field, name: "name", label: "Name", position: 1) }
  let!(:email_field)       { create(:verification_field, name: "email", label: "Email", position: 2) }
  let!(:phone_field)       { create(:verification_field, name: "phone", label: "Phone", position: 3) }
  let!(:postal_code_field) { create(:verification_field, name: "postal_code", label: "Postal code",
                                                         position: 4) }
  let(:user)               { create(:user) }

  before do
    Setting["feature.custom_verification_process"] = true
    Setting["custom_verification_process.remote_census"] = true
    Setting["custom_verification_process.residents"] = true
    Setting["custom_verification_process.sms"] = true
    login_as(user)
  end

  describe "New" do
    scenario "Redirect already verified users to accoung page showing a notice" do
      user.update(residence_verified_at: Time.current)

      visit new_verification_process_path

      expect(page).to have_content "My account"
      expect(page).to have_content "Your account is already verified"
    end

    scenario "Shows all defined verification fields" do
      visit new_verification_process_path

      expect(page).to have_field "verification_process_name"
      expect(page).to have_field "verification_process_email"
      expect(page).to have_field "verification_process_phone"
      expect(page).to have_field "verification_process_postal_code"
    end

    scenario "Shows confirmation fields next to parent fields" do
      name_field.update(confirmation_validation: true)
      visit new_verification_process_path

      expect("Name").to appear_before("Name confirmation")
      expect("Name confirmation").to appear_before("Email")
    end

    scenario "when fields hints are defined it should be shown" do
      name_field.update(hint: "Name hint")
      visit new_verification_process_path

      expect(page).to have_content("Name hint")
    end
  end

  describe "Create" do
    scenario "Shows fields presence validation errors" do
      name_field.update(required: true)
      visit new_verification_process_path

      click_button "Save"

      expect(page).to have_content "1 error prevented this Verification/Process from being saved"
      expect(page).to have_content "can't be blank"
    end

    scenario "Shows fields confirmation validation errors" do
      phone_field.update(confirmation_validation: true)
      visit new_verification_process_path

      fill_in "Phone", with: "666555444"
      fill_in "Phone confirmation", with: "666555443"
      click_button "Save"

      expect(page).to have_content "1 error prevented this Verification/Process from being saved"
      expect(page).to have_content "doesn't match"
    end

    scenario "Shows fields format validation errors" do
      phone_field.update(format: '\A[\d \+]+\z')
      visit new_verification_process_path

      fill_in "Phone", with: "234 234 234A"
      click_button "Save"

      expect(page).to have_content "1 error prevented this Verification/Process from being saved"
      expect(page).to have_content "invalid"
    end

    scenario "Shows special validations from handlers" do
      create(:user, confirmed_phone: "234234234")
      phone_field.update(format: '\A[\d \+]+\z')
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "sms")
      visit new_verification_process_path

      fill_in "Name", with: "My Fabolous Name"
      fill_in "Email", with: "email@example.com"
      fill_in "Phone", with: "234234234"
      click_button "Save"

      expect(page).to have_content "2 errors prevented this Verification/Process from being saved"
      expect(page).to have_content "has already been taken"
    end

    scenario "When one step verification process without active handlers has not errors
              user should be marked as verified user and redirect to profile page with a notice" do
      visit new_verification_process_path

      fill_in "Name", with: "My Fabolous Name"
      fill_in "Email", with: "email@example.com"
      fill_in "Phone", with: "234234234"
      click_button "Save"

      expect(page).to have_content "Your account was successfully verified!"
    end

    scenario "When one step verification process with residents active handler has not errors
              user should be marked as verified user and redirect to profile page with a notice" do
      create(:verification_resident, data: { name: "Fabulous Name",
                                             email: "email@example.com",
                                             phone: "111222333",
                                             postal_code: "00700" })
      create(:verification_handler_field_assignment, verification_field: name_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: email_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: postal_code_field,
        handler: "residents")
      visit new_verification_process_path

      fill_in "Name", with: "Fabulous Name"
      fill_in "Email", with: "email@example.com"
      fill_in "Phone", with: "111222333"
      fill_in "Postal code", with: "00700"
      click_button "Save"

      expect(page).to have_content "Your account was successfully verified!"
    end

    scenario "When one step verification process with residents and sms as active handlers has not errors
              user should be marked as verified user and redirect to profile page with a notice" do
      create(:verification_resident, data: { name: "Fabulous Name",
                                             email: "email@example.com",
                                             phone: "111222333",
                                             postal_code: "00700" })
      create(:verification_handler_field_assignment, verification_field: name_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: email_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "residents")
      create(:verification_handler_field_assignment, verification_field: postal_code_field,
        handler: "residents")
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "sms")
      visit new_verification_process_path

      fill_in "Name", with: "Fabulous Name"
      fill_in "Email", with: "email@example.com"
      fill_in "Phone", with: "111222333"
      fill_in "Postal code", with: "00700"
      click_button "Save"

      expect(page).not_to have_content "Your account was successfully verified!"
      expect(page).to have_content "Enter confirmation codes to verify your account"
      expect(page).to have_field "Sms confirmation code"
    end

    scenario "When two step verification process has not errors user
              should be redirected to confirmation codes page" do
      create(:verification_handler_field_assignment, verification_field: phone_field, handler: "sms")
      visit new_verification_process_path

      fill_in "Name", with: "My Fabolous Name"
      fill_in "Email", with: "email@example.com"
      fill_in "Phone", with: "234234234"
      click_button "Save"

      expect(page).not_to have_content "Your account was successfully verified!"
      expect(page).to have_content "Enter confirmation codes to verify your account"
      expect(page).to have_field "Sms confirmation code"
    end
  end
end
