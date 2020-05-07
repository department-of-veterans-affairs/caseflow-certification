# frozen_string_literal: true

# Run the ETL::Builder regularly.

class ETLBuilderJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :etl

  SLACK_CHANNEL = "#appeals-delta"

  def perform
    RequestStore.store[:current_user] = User.system_user

    sweep_etl
    build_etl
    datadog_report_runtime(metric_group_name: "etl_builder_job")
  end

  private

  def sweep_etl
    start = Time.zone.now
    ETL::Sweeper.new.call
    datadog_report_time_segment(segment: "etl_sweeper", start_time: start)
  end

  def build_etl
    start = Time.zone.now
    etl_build = ETL::Builder.new.incremental
    datadog_report_time_segment(segment: "etl_builder", start_time: start)

    return unless etl_build.built == 0

    msg = "ETL failed to sync any records"
    slack_service.send_notification(msg, self.class.to_s, SLACK_CHANNEL)
  end
end
