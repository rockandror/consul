require "rails_helper"

feature "Admin settings" do

  background do
    @setting1 = create(:setting)
    @setting2 = create(:setting)
    @setting3 = create(:setting)
    login_as(create(:administrator).user)
  end

  scenario "Index" do
    visit admin_settings_path

    expect(page).to have_content @setting1.key
    expect(page).to have_content @setting2.key
    expect(page).to have_content @setting3.key
  end

  scenario "Update" do
    visit admin_settings_path

    within("#edit_setting_#{@setting2.id}") do
      fill_in "setting_#{@setting2.id}", with: "Super Users of level 2"
      click_button "Update"
    end

    expect(page).to have_content "Value updated"
  end

  describe "Update map" do

    scenario "Should not be able when map feature deactivated" do
      Setting["feature.map"] = false
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path
      find("#map-tab").click

      expect(page).to have_content 'To show the map to users you must enable ' \
                                   '"Proposals and budget investments geolocation" ' \
                                   'on "Features" tab.'
      expect(page).not_to have_css("#admin-map")
    end

    scenario "Should be able when map feature activated" do
      Setting["feature.map"] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path
      find("#map-tab").click

      expect(page).to have_css("#admin-map")
      expect(page).not_to have_content 'To show the map to users you must enable ' \
                                       '"Proposals and budget investments geolocation" ' \
                                       'on "Features" tab.'
    end

    scenario "Should show successful notice" do
      Setting["feature.map"] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path

      within "#map-form" do
        click_on "Update"
      end

      expect(page).to have_content "Map configuration updated succesfully"
    end

    scenario "Should display marker by default", :js do
      Setting["feature.map"] = true
      admin = create(:administrator).user
      login_as(admin)

      visit admin_settings_path

      expect(find("#latitude", visible: false).value).to eq "51.48"
      expect(find("#longitude", visible: false).value).to eq "0.0"
    end

    scenario "Should update marker", :js do
      Setting["feature.map"] = true
      admin = create(:administrator).user
      login_as(admin)

      visit admin_settings_path
      find("#map-tab").click
      find("#admin-map").click
      within "#map-form" do
        click_on "Update"
      end

      expect(find("#latitude", visible: false).value).not_to eq "51.48"
      expect(page).to have_content "Map configuration updated succesfully"
    end

  end

  describe "Update Remote Census Configuration" do

    scenario "Should not be able when remote census feature deactivated" do
      Setting["feature.remote_census"] = false
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path
      find("#remote-census-tab").click

      expect(page).to have_content 'To configure remote census (SOAP) you must enable ' \
                                   '"Configure connection to remote census (SOAP)" ' \
                                   'on "Features" tab.'
    end

    scenario "Should be able when remote census feature activated" do
      Setting["feature.remote_census"] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path
      find("#remote-census-tab").click

      expect(page).to have_content("General Information")
      expect(page).to have_content("Request Data")
      expect(page).to have_content("Response Data")
      expect(page).not_to have_content 'To configure remote census (SOAP) you must enable ' \
                                       '"Configure connection to remote census (SOAP)" ' \
                                       'on "Features" tab.'
    end

    scenario "Should redirect to #tab-remote-census-connection after update any remote census setting", :js do
      setting_remote_census = create(:setting, key: "remote_census_general.any_remote_census_general_setting")
      Setting["feature.remote_census"] = true
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path
      find("#remote-census-tab").click

      within("#edit_setting_#{setting_remote_census.id}") do
        fill_in "setting_#{setting_remote_census.id}", with: "New value"
        click_button "Update"
      end

      expect(page).to have_current_path(admin_settings_path)
      expect(page).to have_css("div#tab-remote-census-connection.is-active")
    end

    scenario "Should not redirect to #tab-remote-census-connection after do not update any remote census setting", :js do
      admin = create(:administrator).user
      login_as(admin)
      visit admin_settings_path

      within("#edit_setting_#{@setting1.id}") do
        fill_in "setting_#{@setting1.id}", with: "New value"
        click_button "Update"
      end

      expect(page).to have_current_path(admin_settings_path)
      expect(page).to have_css("div#tab-configuration.is-active")
      expect(page).not_to have_css("div#tab-remote-census-connection.is-active")
    end

  end

  describe "Skip verification" do

    scenario "deactivate skip verification", :js do
      Setting["feature.user.skip_verification"] = "true"
      setting = Setting.where(key: "feature.user.skip_verification").first

      visit admin_settings_path
      find("#features-tab").click

      accept_alert do
        find("#edit_setting_#{setting.id} .button").click
      end

      expect(page).to have_content "Value updated"
    end

    scenario "activate skip verification", :js do
      Setting["feature.user.skip_verification"] = nil
      setting = Setting.where(key: "feature.user.skip_verification").first

      visit admin_settings_path
      find("#features-tab").click

      accept_alert do
        find("#edit_setting_#{setting.id} .button").click
      end

      expect(page).to have_content "Value updated"

      Setting["feature.user.skip_verification"] = nil
    end

  end

end
