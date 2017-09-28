class Hearings::WorksheetsController < HearingsController
  def show
    @hearing_page_title = "Daily Docket | Hearing Worksheet"

    respond_to do |format|
      format.html { render template: "hearings/index" }
      format.json do
        render json: hearing_worksheet
      end
    end
  end

  def update
    worksheet.update!(worksheet_params)
    render json: { worksheet: hearing_worksheet }
  end

  private

  def worksheet
    Hearing.find(params[:hearing_id])
  end
  helper_method :worksheet

  def worksheet_params
    params.require(:worksheet)
          .permit(worksheet_issues_attributes: [:id, :allow, :deny, :remand, :dismiss,
                                                :reopen, :vha, :program, :name, :from_vacols,
                                                :vacols_sequence_id, :_destroy, description: [],
                                                                                levels: []])
  end

  def hearing_worksheet
    worksheet.to_hash_for_worksheet
  end
end
