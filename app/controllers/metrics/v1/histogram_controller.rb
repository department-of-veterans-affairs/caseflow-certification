class Metrics::V1::HistogramController < ApplicationController
  def create
    histograms.each do |_, metric|
      DataDogService.histogram(
        metric_group: metric[:group],
        metric_name: metric[:name],
        metric_value: metric[:value],
        attrs: metric[:attrs],
        app_name: metric[:app_name]
      )
    end

    head :ok
  end

  def histograms
    params.require(:histograms)
  end
end
