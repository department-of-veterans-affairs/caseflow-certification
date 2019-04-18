# frozen_string_literal: true

class Idt::Api::V1::VeteransController < Idt::Api::V1::BaseController
  protect_from_forgery with: :exception
  before_action :verify_access

  # :nocov:
  rescue_from StandardError do |error|
    Raven.capture_exception(error)
    if error.class.method_defined?(:serialize_response)
      render(error.serialize_response)
    else
      render json: { message: "Unexpected error: #{error.message}" }, status: :internal_server_error
    end
  end
  # :nocov:

  rescue_from ActiveRecord::RecordNotFound do |_e|
    render(json: { message: "A veteran with that ssn or file number was not found." }, status: :not_found)
  end

  rescue_from Caseflow::Error::InvalidFileNumber do |_e|
    render(json: { message: "Enter a file number or ssn in the 'FILENUMBER' header" }, status: :unprocessable_entity)
  end

  def details
    render json: json_veteran_details
  end

  private

  def veteran
    fail Caseflow::Error::InvalidFileNumber if file_number.blank?

    @veteran ||= begin
      veteran = Veteran.find_by_file_number_or_ssn(file_number)
      fail ActiveRecord::RecordNotFound unless veteran

      veteran
    end
  end

  def poa
    @poa ||= begin
      bgs = BGSService.new

      poa = bgs.fetch_poa_by_file_number(veteran[:file_number])
      poa.merge(bgs.find_address_by_participant_id(poa[:participant_id]))
    end
  end

  def json_veteran_details
    ::Idt::V1::VeteranDetailsSerializer.new(
      veteran,
      params: {
        poa: poa
      }
    ).serializable_hash[:data]
  end
end
