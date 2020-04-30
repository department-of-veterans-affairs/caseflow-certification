# frozen_string_literal: true

class VirtualHearingSerializer
  include FastJsonapi::ObjectSerializer

  attribute :veteran_email
  attribute :representative_email
  attribute :status
  attribute :request_cancelled
  attribute :client_host do
   VirtualHearing.client_host_or_default
  end
  attribute :alias_with_host, &:formatted_alias_or_alias_with_host
  attribute :host_pin
  attribute :guest_pin
  attribute :job_completed, &:job_completed?
end
