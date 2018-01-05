class Hearings::AppealsController < HearingsController
  def update
    binding.pry
    appeal.update!(appeal_params)
    render json: { appeal: appeal.attributes_for_hearing }
  end

  private

  def appeal
    Appeal.find(params[:appeal_id])
  end
  helper_method :appeal

  def appeal_params
    params.require(:appeal)
          .permit(worksheet_issues_attributes: [:id, :allow, :deny, :remand, :dismiss,
                                                :reopen, :vha, :program, :name, :from_vacols,
                                                :vacols_sequence_id, :_destroy, :notes, :levels])
  end
end
