class Admin::ValuatorGroupsController < Admin::BaseController

  def index
    @groups = ValuatorGroup.all.page(params[:page])
  end

  def show
    @group = ValuatorGroup.find(params[:id])
  end

  def new
    @group = ValuatorGroup.new
  end

  def edit
    @group = ValuatorGroup.find(params[:id])
  end

  def create
    @group = ValuatorGroup.new(group_params)
    if @group.save
      notice = t("valuator_group.notice.created")
      redirect_to admin_valuator_groups_path, notice: notice
    else
      render :new
    end
  end

  def update
    @group = ValuatorGroup.find(params[:id])
    if @group.update(group_params)
      notice = t("valuator_group.notice.updated")
      redirect_to [:admin, @group], notice: notice
    else
      render :edit
    end
  end

  def destroy
    @group = ValuatorGroup.find(params[:id])
    @group.destroy
    notice = t("valuator_group.notice.destroyed")
    redirect_to admin_valuator_groups_path, notice: notice
  end

  private

    def group_params
      params.require(:valuator_group).permit(:name)
    end

end