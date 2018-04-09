class AppealsController < ApplicationController
  def index
    return veteran_id_not_found_error unless veteran_id

    MetricsService.record("VACOLS: Get appeal information for file_number #{veteran_id}",
                          name: "QueueController.appeals") do

      # TODO: fix the way this structure looks, currently it returns as:
      # { appeals: { data: [{},{},{}] } } # Get rid of the data element and return the array as the appeals element.
      # Look at other serializers.
      # 
      
    # TODO: Catch RecordNotFounds here and return them as an empty array.

    begin
      appeals = Appeal.fetch_appeals_by_file_number(veteran_id)
    rescue ActiveRecord::RecordNotFound
      appeals = []
    end

      render json: {
        shouldUseAppealSearch: feature_enabled?(:should_use_appeal_search),
        appeals: json_appeals(appeals)
      }
    end
  end

  private

  def veteran_id
    request.headers["HTTP_VETERAN_ID"]
  end

  def veteran_id_not_found_error
    render json: {
      "errors": [
        "title": "Must include Veteran ID",
        "detail": "Veteran ID should be included as HTTP_VETERAN_ID element of request headers"
      ]
    }, status: 400
  end

  def json_appeals(appeals)
    ActiveModelSerializers::SerializableResource.new(
      appeals,
      each_serializer: ::WorkQueue::AppealSerializer
    ).as_json
  end
end
