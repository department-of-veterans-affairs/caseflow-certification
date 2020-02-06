# frozen_string_literal: true

class ExternalApi::VbmsDocumentSeriesForAppeal < ExternalApi::VbmsRequestWithFileNumber
  def fetch
    get_and_retry
  end

  protected

  def do_request(file_number_or_claim_number)
    if FeatureToggle.enabled?(:vbms_pagination, user: RequestStore[:current_user])
      service = VBMS::Service::PagedDocuments.new(client: vbms_client)

      ExternalApi::VBMSService.call_and_log_service(
        service: service, 
        vbms_id: file_number_or_claim_number
      )&.[](:documents) || []
    else
      request = VBMS::Requests::FindDocumentSeriesReference.new(file_number_or_claim_number)

      ExternalApi::VBMSService.send_and_log_request(
        file_number_or_claim_number,
        request,
        override_vbms_client = vbms_client
      )
    end
  end
end
