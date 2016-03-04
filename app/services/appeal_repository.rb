require "vbms"

class CaseflowLogger
  def log(event, data)
    case event
    when :request
      if data[:response_code] != 200
        Rails.logger.error(
          "VBMS HTTP Error #{data[:response_code]} " \
          "(#{data[:request].class.name}) #{data[:response_body]}"
        )
      end
    end
  end
end

class AppealRepository
  FORM_8_DOC_TYPE_ID = 178

  def self.find(vacols_id, _args = {})
    case_record = Records::Case.includes(:folder, :correspondent).find(vacols_id)

    appeal = Appeal.from_records(
      case_record: case_record,
      folder_record: case_record.folder,
      correspondent_record: case_record.correspondent
    )

    appeal.documents = fetch_documents_for(appeal).map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end

    appeal
  end

  def self.certify(appeal)
    appeal.case_record.bfdcertool = Time.zone.now
    appeal.case_record.bf41stat = Time.zone.now.to_s(:va_date)
    appeal.case_record.save!

    upload_form8_for(appeal)
  end

  def self.sanitize_vbms_id(vbms_id)
    "0000#{vbms_id.gsub(/[^0-9]/, '')}"[-8..-1]
  end

  def self.upload_form8_for(appeal)
    @vbms_client ||= init_vbms_client

    form8 = Form8.from_appeal(appeal)
    request = VBMS::Requests::UploadDocumentWithAssociations.new(
      sanitize_vbms_id(appeal.vbms_id),
      Time.zone.now,
      appeal.veteran_first_name,
      appeal.veteran_middle_initial,
      appeal.veteran_last_name,
      "Form 8",
      form8.pdf_location,
      FORM_8_DOC_TYPE_ID,
      "VACOLS",
      true
    )

    @vbms_client.send(request)
    File.delete(form8.pdf_location)
  end

  def self.fetch_documents_for(appeal)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::ListDocuments.new(sanitize_vbms_id(appeal.vbms_id))
    @vbms_client.send_request(request)
  end

  def self.vbms_config
    config = Rails.application.secrets.vbms.clone

    %w(keyfile saml key cacert cert).each do |file|
      config[file] = File.join(config["env_dir"], config[file])
    end

    config
  end

  def self.init_vbms_client
    VBMS::Client.new(
      vbms_config["url"],
      vbms_config["keyfile"],
      vbms_config["saml"],
      vbms_config["key"],
      vbms_config["keypass"],
      vbms_config["cacert"],
      vbms_config["cert"],
      logger: CaseflowLogger.new
    )
  end
end
