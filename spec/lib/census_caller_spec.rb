require "rails_helper"

describe CensusCaller do
  let(:api) { described_class.new }

  describe "#call" do
    it "returns data from local_census_records if census API is not available" do
      census_api_response = CensusApi::Response.new(get_habita_datos_response: {
          get_habita_datos_return: { datos_habitante: {}, datos_vivienda: {} }
        }
      )

      local_census_response = LocalCensus::Response.new(create(:local_census_record))

      expect_any_instance_of(CensusApi).to   receive(:call).and_return(census_api_response)
      expect_any_instance_of(LocalCensus).to receive(:call).and_return(local_census_response)

      allow(CensusApi).to   receive(:call).with(1, "12345678A")
      allow(LocalCensus).to receive(:call).with(1, "12345678A")

      response = api.call(1, "12345678A", nil, nil)

      expect(response).to eq(local_census_response)
    end

    it "returns data from census API if it's available and valid" do
      census_api_response = CensusApi::Response.new(get_habita_datos_response: {
        get_habita_datos_return: {
          datos_habitante: { item: { fecha_nacimiento_string: "1-1-1980" } }
        }
      })

      local_census_response = LocalCensus::Response.new(create(:local_census_record))

      expect_any_instance_of(CensusApi).to  receive(:call).and_return(census_api_response)
      allow_any_instance_of(LocalCensus).to receive(:call).and_return(local_census_response)

      allow(CensusApi).to receive(:call).with(1, "12345678A")
      allow(LocalCensus).to receive(:call).with(1, "12345678A")

      response = api.call(1, "12345678A", nil, nil)

      expect(response).to eq(census_api_response)
    end

    it "returns data from Remote Census API if it's available and valid" do
      Setting["feature.remote_census"] = true
      access_user_data = "get_habita_datos_response.get_habita_datos_return.datos_habitante.item"
      access_residence_data = "get_habita_datos_response.get_habita_datos_return.datos_vivienda.item"
      Setting["remote_census.response.date_of_birth"] = "#{access_user_data}.fecha_nacimiento_string"
      Setting["remote_census.response.postal_code"] = "#{access_residence_data}.codigo_postal"
      Setting["remote_census.response.district"] = "#{access_residence_data}.codigo_distrito"
      Setting["remote_census.response.gender"] = "#{access_user_data}.descripcion_sexo"
      Setting["remote_census.response.name"] = "#{access_user_data}.nombre"
      Setting["remote_census.response.surname"] = "#{access_user_data}.apellido1"
      Setting["remote_census.response.valid"] = access_user_data

      remote_census_api_response = RemoteCensusApi::Response.new(get_habita_datos_response: {
        get_habita_datos_return: {
          datos_habitante: { item: { fecha_nacimiento_string: "1-1-1980" } }
        }
      })

      local_census_response = LocalCensus::Response.new(create(:local_census_record))

      expect_any_instance_of(RemoteCensusApi).to receive(:call).and_return(remote_census_api_response)
      allow_any_instance_of(LocalCensus).to receive(:call).and_return(local_census_response)

      allow(RemoteCensusApi).to receive(:call).with(1, "12345678A")
      allow(LocalCensus).to receive(:call).with(1, "12345678A")

      response = api.call(1, "12345678A")

      expect(response).to eq(remote_census_api_response)

      Setting["feature.remote_census"] = nil
    end
  end

end
