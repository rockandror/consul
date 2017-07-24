shared_examples "documentable" do |documentable_factory_name, documentable_path, documentable_path_arguments, document_trait|
  include ActionView::Helpers
  include DocumentsHelper
  include DocumentablesHelper

  let!(:administrator)          { create(:user) }
  let!(:user)                   { create(:user) }
  let!(:arguments)              { {} }
  let!(:documentable)           { create(documentable_factory_name, author: user) }
  let!(:documentable_dom_name)  { documentable_factory_name.parameterize }

  before do
    create(:administrator, user: administrator)

    documentable_path_arguments.each do |argument_name, path_to_value|
      arguments.merge!("#{argument_name}": documentable.send(path_to_value))
    end
  end

  context "Show" do

    scenario "Should not display upload document button when there is no logged user" do
      visit send(documentable_path, arguments)

      within "##{dom_id(documentable)}" do
        expect(page).not_to have_link("Upload document")
      end
    end

    scenario "Should not display upload document button when maximum number of documents reached " do
      create_list(:document, 3, document_trait, documentable: documentable)
      visit send(documentable_path, arguments)

      within "##{dom_id(documentable)}" do
        expect(page).not_to have_link("Upload document")
      end
    end

    scenario "Should display upload document button when user is logged in and is documentable owner" do
      login_as(user)

      visit send(documentable_path, arguments)

      within "##{dom_id(documentable)}" do
        expect(page).to have_link("Upload document")
      end
    end

    scenario "Should display upload document button when admin is logged in" do
      login_as(administrator)

      visit send(documentable_path, arguments)

      within "##{dom_id(documentable)}" do
        expect(page).to have_link("Upload document")
      end
    end

    scenario "Should navigate to new document page when click un upload button" do
      login_as(user)

      visit send(documentable_path, arguments)
      click_link  "Upload document"

      expect(page).to have_selector("h1", text: "Upload document")
    end

    describe "Documents tab" do

      let!(:document) { create(:document, document_trait, documentable: documentable, user: documentable.author)}

      scenario "Should display maximum number of documents alert when reached" do
        create_list(:document, 2, document_trait, documentable: documentable)
        visit send(documentable_path, arguments)

        within "#tab-documents" do
          expect(page).to have_content "You have reached the maximum number of documents allowed! You have to delete one before you can upload another."
        end
      end

      scenario "Download action Should be able to anyone" do
        visit send(documentable_path, arguments)

        within "#tab-documents" do
          if document_trait == :file_document
            expect(page).to have_link("Download PDF")
          else
            expect(page).to have_link("Go to link")
          end
        end
      end

      scenario "Follow link button should add http URI schema to stored link when no schema present" do
        document.update_attribute(:link, "www.example.com") if document_trait == :link_document
        visit send(documentable_path, arguments)

        within "#tab-documents" do
          if document_trait == :file_document
            expect(page).not_to have_link("Go to link")
          else
            expect(page).to have_link("Go to link", href: "http://www.example.com" )
          end
        end
      end

      scenario "Download and Follow links should have blank target attribute" do
        document.update_attribute(:link, "www.example.com") if document_trait == :link_document
        visit send(documentable_path, arguments)

        within "#tab-documents" do
          if document_trait == :file_document
            expect(page).to have_selector("a[target=_blank]", text: "Download PDF")
          else
            expect(page).to have_selector("a[target=_blank]", text: "Go to link")
          end
        end
      end

      scenario "Download and Follow links should have rel attribute setted to no follow" do
        document.update_attribute(:link, "www.example.com") if document_trait == :link_document
        visit send(documentable_path, arguments)

        within "#tab-documents" do
          if document_trait == :file_document
            expect(page).to have_selector("a[rel=nofollow]", text: "Download PDF")
          else
            expect(page).to have_selector("a[rel=nofollow]", text: "Go to link")
          end
        end
      end

      describe "Destroy action" do

        scenario "Should not be able when no user logged in" do
          visit send(documentable_path, arguments)

          within "#tab-documents" do
            expect(page).not_to have_link("Destroy")
          end
        end

        scenario "Should be able when documentable author is logged in" do
          login_as documentable.author
          visit send(documentable_path, arguments)

          within "#tab-documents" do
            expect(page).to have_link("Destroy")
          end
        end

        scenario "Should be able when any administrator logged in" do
          login_as administrator
          visit send(documentable_path, arguments)

          within "#tab-documents" do
            expect(page).to have_link("Destroy")
          end
        end

      end

    end

  end

  context "New" do

    scenario "Should not be able for unathenticated users" do
      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id)

      expect(page).to have_content("You must sign in or register to continue.")
    end

    scenario "Should not be able for other users" do
      login_as create(:user)

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id)

      expect(page).to have_content("You do not have permission to carry out the action 'new' on document. ")
    end

    scenario "Should be able to documentable author" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id)

      expect(page).to have_selector("h1", text: "Upload document")
    end

    scenario "should show source file option checked by deafult ", :js do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))

      expect(page).to have_content "Choose attachment file"
    end

    scenario "Should show link field when source link option checked", :js do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))
      find('#document_source_link').click

      expect(page).not_to have_content "Choose attachment file"
      expect(page).to have_selector "#document_link"
    end

    scenario "Should accept only documentable allowed content types" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))

      expect(page).to have_selector "input[type=file][accept='#{accepted_content_types_extensions(documentable)}']"
    end

    scenario "Should show documentable custom recomentations" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))

      expect(page).to have_content "You can upload up to a maximum of #{max_file_size(documentable)} documents"
      expect(page).to have_content "You can upload #{humanized_accepted_content_types(documentable)} files or external links to websites or files."
      expect(page).to have_content "You can upload files up to #{max_file_size(documentable)} MB"
    end

  end

  context "Create" do

    scenario "Should show validation errors" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id)
      click_on "Upload document"

      expect(page).to have_content "2 errors prevented this Document from being saved: "
      expect(page).to have_selector "small.error:not(.show-for-sr)", text: "can't be blank", count: 2
      expect(page).to have_selector "small.show-for-sr", text: "can't be blank", count: 1
    end

    scenario "Should display file name after file selection", :js do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id)
      attach_file :document_attachment, "spec/fixtures/files/empty.pdf"

      expect(page).to have_content "empty.pdf"
    end

    scenario "Should show error notice after unsuccessfull document upload" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))
      attach_file :document_attachment, "spec/fixtures/files/empty.pdf"
      click_on "Upload document"

      expect(page).to have_content "Cannot create document. Check form errors and try again."
    end

    scenario "Should show success notice after successfull document upload" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))
      fill_in :document_title, with: "Document title"
      attach_file :document_attachment, "spec/fixtures/files/empty.pdf"
      click_on "Upload document"

      expect(page).to have_content "Document was created successfully."
    end

    scenario "Should redirect to documentable path after successfull document upload" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))
      fill_in :document_title, with: "Document title"
      attach_file :document_attachment, "spec/fixtures/files/empty.pdf"
      click_on "Upload document"

      within "##{dom_id(documentable)}" do
        expect(page).to have_selector "h1", text: documentable.title
      end
    end

    scenario "Should show new document on documentable documents tab after successfull document upload" do
      login_as documentable.author

      visit new_document_path(documentable_type: documentable.class.name,
                              documentable_id: documentable.id,
                              from: send(documentable_path, arguments))
      fill_in :document_title, with: "Document title"
      attach_file :document_attachment, "spec/fixtures/files/empty.pdf"
      click_on "Upload document"

      expect(page).to have_link "Documents (1)"
      within "#tab-documents" do
        within "#document_#{Document.last.id}" do
          expect(page).to have_content "Document title"
          expect(page).to have_link "Download PDF"
          expect(page).to have_link "Destroy"
        end
      end
    end

  end

  context "Destroy" do

    let!(:document) { create(:document, document_trait, documentable: documentable, user: documentable.author) }

    scenario "Should show success notice after successfull document upload" do
      login_as documentable.author

      visit send(documentable_path, arguments)
      within "#tab-documents" do
        within "#document_#{document.id}" do
          click_on "Destroy"
        end
      end

      expect(page).to have_content "Document was deleted successfully."
    end

    scenario "Should update documents tab count after successful deletion" do
      login_as documentable.author

      visit send(documentable_path, arguments)
      within "#tab-documents" do
        within "#document_#{document.id}" do
          click_on "Destroy"
        end
      end

      expect(page).to have_link "Documents (0)"
    end

    scenario "Should redirect to documentable path after successful deletion" do
      login_as documentable.author

      visit send(documentable_path, arguments)
      within "#tab-documents" do
        within "#document_#{document.id}" do
          click_on "Destroy"
        end
      end

      within "##{dom_id(documentable)}" do
        expect(page).to have_selector "h1", text: documentable.title
      end
    end

  end

end
