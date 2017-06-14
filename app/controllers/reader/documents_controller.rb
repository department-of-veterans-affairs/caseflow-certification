class Reader::DocumentsController < Reader::AppealController
  before_action :verify_access, :verify_reader_feature_enabled, :set_application

  def index
    respond_to do |format|
      format.html { return render(:index) }
      format.json do
        MetricsService.record "Get appeal #{appeal_id} document data" do
          render json: {
            appealDocuments: documents,
            annotations: annotations
          }
        end
      end
    end
  end

  def show
    # If we have sufficient metadata to show a single document,
    # then we'll render the show. Otherwise we want to render index
    # which will grab the metadata for all documents
    return render(:index) unless metadata?
  end

  private

  def appeal
    @appeal ||= Appeal.find_or_create_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def annotations
    appeal.saved_documents.flat_map(&:annotations).map(&:to_hash)
  end

  def documents
    document_ids = appeal.saved_documents.map(&:id)

    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id:  document_ids)
                                      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    @documents = appeal.saved_documents.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
        object[:tags] = document.tags
      end
    end
  end

  def metadata?
    params[:received_at] && params[:type] && params[:filename]
  end

  # :nocov:
  def single_document
    Document.find(params[:id]).tap do |t|
      t.filename = params[:filename]
      t.type = params[:type]
      t.received_at = params[:received_at]
    end
  end
  helper_method :single_document
  # :nocov:

  def appeal_id
    params[:appeal_id]
  end

  def verify_reader_feature_enabled
    verify_feature_enabled(:reader)
  end

  def verify_access
    verify_authorized_roles("Reader")
  end

  def set_application
    RequestStore.store[:application] = "reader"
  end
end
