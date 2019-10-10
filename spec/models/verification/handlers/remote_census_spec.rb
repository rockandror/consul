require "rails_helper"

describe Verification::Handlers::RemoteCensus do
  it "its id is 'remote_census'" do
    expect(Verification::Handlers::RemoteCensus.id).to eq("remote_census")
  end

  it "its a handler that do not requires a confirmation code" do
    expect(Verification::Handlers::RemoteCensus.requires_confirmation?).to be false
  end

  describe "#verify" do
    let(:user) { create(:user) }
    let(:remote_census_handler) { Verification::Handlers::RemoteCensus.new }

    before do
      document_number_field = create(:verification_field, name: :document_number)
      document_type_field = create(:verification_field, name: :document_type)
      create(:verification_handler_field_assignment, verification_field: document_number_field,
        handler: :remote_census)
      create(:verification_handler_field_assignment, verification_field: document_type_field,
        handler: :remote_census)
    end

    it "returns error response when force with attributes sended a stubbed_invalid_response" do
      attributes = { document_number: "12345678Z", document_type: "invalid_document_type", user: user }
      response = remote_census_handler.verify(attributes)

      expect(response.success?).not_to be true
      expect(response.error?).to be true
    end

    it "returns error response when response not contains valid condition defined" do
      Setting["remote_census.response.valid"] = "path.that_is_not_contained.on_response"
      attributes = { document_number: "12345678Z", document_type: "1", user: user }
      response = remote_census_handler.verify(attributes)

      expect(response.success?).not_to be true
      expect(response.error?).to be true
    end

    it "returns error response when verification response fields is not valid" do
      valid_response_path = "get_habita_datos_response.get_habita_datos_return.datos_habitante.item"
      Setting["remote_census.response.valid"] = valid_response_path
      field = create(:verification_field, name: :postal_code)
      response_path = "get_habita_datos_response.get_habita_datos_return.datos_vivienda.item.codigo_postal"
      create(:verification_handler_field_assignment, verification_field: field,
        handler: :remote_census, response_path: response_path)

      attributes = { document_number: "12345678Z", document_type: "1", postal_code: "00001", user: user }
      response = remote_census_handler.verify(attributes)

      expect(response.success?).not_to be true
      expect(response.error?).to be true
    end

    it "returns success response when all validation passes" do
      valid_response_path = "get_habita_datos_response.get_habita_datos_return.datos_habitante.item"
      Setting["remote_census.response.valid"] = valid_response_path
      field = create(:verification_field, name: :postal_code)
      response_path = "get_habita_datos_response.get_habita_datos_return.datos_vivienda.item.codigo_postal"
      create(:verification_handler_field_assignment, verification_field: field,
        handler: :remote_census, response_path: response_path)

      attributes = { document_number: "12345678Z", document_type: "1", postal_code: "28013", user: user }
      response = remote_census_handler.verify(attributes)

      expect(response.success?).to be true
      expect(response.error?).not_to be true
    end
  end
end