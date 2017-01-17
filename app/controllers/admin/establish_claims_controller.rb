class Admin::EstablishClaimsController < ApplicationController
  def show
    @appeal = Appeal.new
    @existing_tasks = EstablishClaim.newest_first.limit(100)
  end

  def create
    vbms_id = params[:appeal][:vbms_id]
    appeal = Appeal.find_or_create_by_vbms_id(vbms_id)
    task = EstablishClaim.find_or_create_by(appeal: appeal)

    flash[:success] = "Task created or already existed"
    redirect_to admin_establish_claim_path

  rescue MultipleAppealsByVBMSIDError
    flash[:error] = "Multiple appeals detected. Please try another VBMS ID"
    redirect_to admin_establish_claim_path
  end
end
