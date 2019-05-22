require "rails_helper"

describe LocalCensusRecords::Importation do

  let(:base_files_path) { %w[spec fixtures files local_census_records importation] }
  let(:importation) { build(:local_census_records_importation) }

  describe "Validations" do
    it "is valid" do
      expect(importation).to be_valid
    end

    it "is not valid without a file to import" do
      importation.file = nil

      expect(importation).not_to be_valid
    end

    context "When file extension" do
      it "is wrong it should not be valid" do
        file = Rack::Test::UploadedFile.new("spec/fixtures/files/clippy.gif")
        importation = build(:local_census_records_importation, file: file)

        expect(importation).not_to be_valid
      end

      it "is csv it should be valid" do
        path = base_files_path << "valid.csv"
        file = Rack::Test::UploadedFile.new(Rails.root.join(*path))
        importation = build(:local_census_records_importation, file: file)

        expect(importation).to be_valid
      end
    end

    context "When file headers" do
      it "are all missing it should not be valid" do
        path = base_files_path << "valid-without-headers.csv"
        file = Rack::Test::UploadedFile.new(Rails.root.join(*path))
        importation = build(:local_census_records_importation, file: file)

        expect(importation).not_to be_valid
      end
    end
  end

  context "#save" do
    it "Create valid local census records with provided values" do
      importation.save
      local_census_record = LocalCensusRecord.find_by(document_number: "X11556678")

      expect(local_census_record).not_to be_nil
      expect(local_census_record.document_type).to eq("NIE")
      expect(local_census_record.document_number).to eq("X11556678")
      expect(local_census_record.date_of_birth).to eq(Date.parse("07/08/1987"))
      expect(local_census_record.postal_code).to eq("7008")
    end

    it "Add successfully created local census records to created_records array" do
      importation.save

      valid_document_numbers = ["44556678T", "33556678T", "22556678T", "X11556678"]
      expect(importation.created_records.collect(&:document_number)).to eq(valid_document_numbers)
    end

    it "Add invalid local census records to invalid_records array" do
      path = base_files_path << "invalid.csv"
      file = Rack::Test::UploadedFile.new(Rails.root.join(*path))
      importation.file = file

      importation.save

      invalid_records_document_types = [nil, "DNI", "Passport", "NIE"]
      invalid_records_document_numbers = ["44556678T", nil, "22556678T", "X11556678"]
      invalid_records_date_of_births = [Date.parse("07/08/1984"), Date.parse("07/08/1985"), nil,
        Date.parse("07/08/1987")]
      invalid_records_postal_codes = ["7008", "7009", "7010", nil]
      expect(importation.invalid_records.collect(&:document_type))
        .to eq(invalid_records_document_types)
      expect(importation.invalid_records.collect(&:document_number))
        .to eq(invalid_records_document_numbers)
      expect(importation.invalid_records.collect(&:date_of_birth))
        .to eq(invalid_records_date_of_births)
      expect(importation.invalid_records.collect(&:postal_code))
      .to eq(invalid_records_postal_codes)
    end

    it "Add duplicated local census records to invalid_records array" do
      attributes = { document_type: "DNI", document_number: "44556678T",
        date_of_birth: "07/08/1984", postal_code: "7008" }
      create(:local_census_record, **attributes)
      attributes = { document_type: "DNI", document_number: "33556678T",
        date_of_birth: "07/08/1985", postal_code: "7008" }
      create(:local_census_record, **attributes)
      attributes = { document_type: "DNI", document_number: "22556678T",
        date_of_birth: "07/08/1986", postal_code: "7008" }
      create(:local_census_record, **attributes)
      attributes = { document_type: "NIE", document_number: "X11556678",
        date_of_birth: "07/08/1987", postal_code: "7008" }
      create(:local_census_record, **attributes)
      path = base_files_path << "valid.csv"
      file = Rack::Test::UploadedFile.new(Rails.root.join(*path))
      importation.file = file

      importation.save

      expect(importation.invalid_records.count).to eq 4
      invalid_records_document_numbers = ["44556678T", "33556678T", "22556678T", "X11556678"]
      expect(importation.invalid_records.collect(&:document_number))
        .to eq(invalid_records_document_numbers)
    end
  end
end
