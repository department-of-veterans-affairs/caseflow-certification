class CertificationsController < ApplicationController
  def new
    render "mismatched_documents" unless appeal.ready_to_certify?
  end

  private

  def appeal
    @appeal ||= Appeal.find(params[:vacols_id])
  end
  helper_method :appeal
end
