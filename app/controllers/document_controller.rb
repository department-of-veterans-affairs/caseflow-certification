class DocumentController < ApplicationController
  before_action :verify_system_admin

  # :nocov:
  def update
    document = Document.find(params[:id])
    document.update!(update_params)
    render json: {}
  end

  def update_params
    params.permit(:label)
  end

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.find(params[:id])

    # The line below enables document caching for a month.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end

  def mark_as_read
    DocumentView.find_or_create_by(
      document_id: params[:id],
      user_id: current_user.id).tap do |t|
      t.update!(first_viewed_at: Time.zone.now) unless t.first_viewed_at
    end
    render json: {}
  end
  # :nocov:
end
