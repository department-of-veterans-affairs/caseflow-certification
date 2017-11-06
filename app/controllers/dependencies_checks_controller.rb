class DependenciesChecksController < ApplicationBaseController
  newrelic_ignore
  
  def show
    render json: { dependencies_outage: DependenciesReportService.outage_present? }
  end
end
