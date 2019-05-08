require "rails_helper"

feature "Admin local census records" do

  background do
    login_as(create(:administrator).user)
  end

  context "Index" do
    let!(:local_census_record) { create(:local_census_record) }

    scenario "Should show empty message when no local census records exists" do
      LocalCensusRecord.delete_all
      visit admin_local_census_records_path

      expect(page).to have_content("There are no local census records.")
    end

    scenario "Should show existing local census records" do
      visit admin_local_census_records_path

      expect(page).to have_content(local_census_record.document_type)
      expect(page).to have_content(local_census_record.document_number)
      expect(page).to have_content(local_census_record.date_of_birth)
      expect(page).to have_content(local_census_record.postal_code)
    end

    scenario "Should show edit and destroy actions for each record" do
      visit admin_local_census_records_path

      within "#local_census_record_#{local_census_record.id}" do
        expect(page).to have_link "Edit"
        expect(page).to have_link "Delete"
      end
    end

    scenario "Should show page entries info" do
      visit admin_local_census_records_path

      expect(page).to have_content("There is 1 local census record")
    end

    scenario "Should show paginator" do
      create_list(:local_census_record, 25)
      visit admin_local_census_records_path

      within ".pagination" do
        expect(page).to have_link("2")
      end
    end

    context "Search" do
      background do
        create(:local_census_record, document_number: "X66777888" )
      end

      scenario "Should show matching records by document number at first visit" do
        visit admin_local_census_records_path(search: "X66777888")

        expect(page).to have_content "X66777888"
        expect(page).not_to have_content local_census_record.document_number
      end

      scenario "Should show matching records by document number", :js do
        visit admin_local_census_records_path

        fill_in :search, with: "X66777888"
        click_on "Search"

        expect(page).to have_content "X66777888"
        expect(page).not_to have_content local_census_record.document_number
      end
    end
  end

  context "Create" do
    scenario "Should show validation errors" do
      visit new_admin_local_census_record_path

      click_on "Save"

      expect(page).to have_content "4 errors prevented this Local Census Record from being saved."
      expect(page).to have_content "can't be blank", count: 4
    end

    scenario "Should show successful notice after create valid record" do
      visit new_admin_local_census_record_path

      fill_in :local_census_record_document_type, with: "DNI"
      fill_in :local_census_record_document_number, with: "#DOCUMENT"
      fill_in :local_census_record_date_of_birth, with: "07/07/1982"
      fill_in :local_census_record_postal_code, with: "07003"
      click_on "Save"

      expect(page).to have_content "New local census record created successfully!"
      expect(page).to have_content "DNI"
      expect(page).to have_content "#DOCUMENT"
      expect(page).to have_content "1982-07-07"
      expect(page).to have_content "07003"
    end
  end

  context "Update" do
    let!(:local_census_record) { create(:local_census_record) }

    scenario "Should show validation errors" do
      visit edit_admin_local_census_record_path(local_census_record)

      fill_in :local_census_record_document_number, with: ""
      click_on "Save"

      expect(page).to have_content "1 error prevented this Local Census Record from being saved."
      expect(page).to have_content "can't be blank", count: 1
    end

    scenario "Should show successful notice after valid update" do
      visit edit_admin_local_census_record_path(local_census_record)

      fill_in :local_census_record_document_type, with: "NIE"
      fill_in :local_census_record_document_number, with: "#NIE_NUMBER"
      fill_in :local_census_record_date_of_birth, with: "08/08/1982"
      fill_in :local_census_record_postal_code, with: "07007"
      click_on "Save"

      expect(page).to have_content "Local census record updated successfully!"
      expect(page).to have_content "NIE"
      expect(page).to have_content "#NIE_NUMBER"
      expect(page).to have_content "1982-08-08"
      expect(page).to have_content "07007"
    end
  end
end
