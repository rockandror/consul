class Admin::LocalCensusRecordsController < Admin::BaseController
  load_and_authorize_resource

  def index
    @local_census_records = @local_census_records.search(params[:search])
    @local_census_records = @local_census_records.page(params[:page])
  end

  def create
    @local_census_record = LocalCensusRecord.new(local_census_record_params)
    if @local_census_record.save
      redirect_to admin_local_census_records_path, notice: t(".notice")
    else
      render :new
    end
  end

  private

    def local_census_record_params
      attributes = [:document_type, :document_number, :date_of_birth, :postal_code]
      params.require(:local_census_record).permit(*attributes)
    end
end
