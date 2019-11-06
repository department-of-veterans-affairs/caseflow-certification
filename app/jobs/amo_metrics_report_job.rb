# frozen_string_literal: true

class AMOMetricsReportJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :intake

  SLACK_CHANNEL = "#caseflow-vbms-intake"

  def perform
    setup_dates
    async_stats = ClaimReviewAsyncStatsReporter.new(start_date: start_date, end_date: end_date)
    send_report(async_stats: async_stats)
  end

  private

  attr_reader :start_date, :end_date

  def setup_dates
    # if we're mid-month, do month-to-date
    # otherwise, the full previous month.
    if Time.zone.today < Time.zone.today.at_end_of_month
      @start_date = Time.zone.today.at_beginning_of_month
      @end_date = Time.zone.tomorrow # tomorrow so we get all of today
    else
      @start_date = Time.zone.today.prev_month.at_beginning_of_month
      @end_date = Time.zone.today.prev_month.at_end_of_month
    end
  end

  def send_report(async_stats:)
    msg = build_report(async_stats)
    slack_service.send_notification(msg, self.class.to_s, SLACK_CHANNEL)
  end

  def build_report(async_stats)
    sc_stats = async_stats.stats[:supplemental_claims]
    hlr_stats = async_stats.stats[:higher_level_reviews]
    sc_avg = async_stats.seconds_to_hms(sc_stats[:avg].to_i)
    hlr_avg = async_stats.seconds_to_hms(hlr_stats[:avg].to_i)
    sc_med = async_stats.seconds_to_hms(sc_stats[:median].to_i)
    hlr_med = async_stats.seconds_to_hms(hlr_stats[:median].to_i)
    report = []
    report << "AMO metrics report #{start_date} to #{end_date - 1.day}"
    report << "Supplemental Claims #{sc_stats[:total]} established, median #{sc_med} average #{sc_avg}"
    report << "Higher Level Reviews #{hlr_stats[:total]} established, median #{hlr_med} average #{hlr_avg}"
    report << async_stats.as_csv
    report.join("\n")
  end
end
