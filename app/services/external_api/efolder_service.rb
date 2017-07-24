require "HTTPI"
require "json"

class ExternalApi::EfolderService
  def self.fetch_document_file(user, document)
    # Makes a GET request to <efolder>/documents/<vbms_doc_id>
    uri = URI.escape(efolder_base_url + "/api/v1/documents/" + document.vbms_document_id)
    result = get_efolder_response(uri)
    result && result.content
  end

  def self.fetch_documents_for(user, appeal)
    # Makes a GET request to <efolder>/files/<file_number>
    headers = { "FILE-NUMBER" => appeal.veteran.file_number }
    documents = get_efolder_response(efolder_base_url + "/files", headers)

    Rails.logger.info("# of Documents retrieved from efolder: #{documents.length}")

    documents.map do |efolder_document|
      Document.from_efolder(efolder_document)
    end
  end

  def self.efolder_base_url
    Rails.application.config.efolder_url
  end

  def self.efolder_key
    Rails.application.config.efolder_key
  end

  def self.get_efolder_response(url, headers = {})
    response = []

    url = URI.escape(url)
    MetricsService.record "eFolder GET request to #{url}" do
      request = HTTPI::Request.new(url)

      headers["AUTHORIZATION"] = "Token token=#{efolder_key}"
      headers["CSS-ID"] = user.css_id
      headers["STATION-ID"] = user.station_id
      request.headers = headers

      response = HTTPI.get(request)
    end

    if response.error?
      Rails.logger.error "Error sending request to eFolder: #{url}. HTTP Status Code: #{response.code}"
    else
      response = JSON.parse(response.body)["data"]
    end

    response
  end
end
