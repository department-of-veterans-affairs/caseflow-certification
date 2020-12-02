require "#{Rails.root}/app/jobs/middleware/job_monitoring_middleware"
require "#{Rails.root}/app/jobs/middleware/job_request_store_middleware"
require "#{Rails.root}/app/jobs/middleware/job_sentry_scope_middleware"

# set up default exponential backoff parameters
ActiveJob::QueueAdapters::ShoryukenAdapter::JobWrapper
  .shoryuken_options(retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours])

if Rails.application.config.sqs_endpoint
  # override the sqs_endpoint
  Shoryuken::Client.sqs.config[:endpoint] = URI(Rails.application.config.sqs_endpoint)
end

if Rails.application.config.sqs_create_queues
  # create the development queues
  Shoryuken::Client.sqs.create_queue({ queue_name: ActiveJob::Base.queue_name_prefix + '_low_priority' })
  Shoryuken::Client.sqs.create_queue({ queue_name: ActiveJob::Base.queue_name_prefix + '_high_priority' })
end

Shoryuken.configure_server do |config|
  # Configure loggers in Shoryuken.
  #
  # Note: `Rails.logger` is an `ActiveSupport::TaggedLogging` logger in production. You can't
  #   override the logger format because tagged logger formatters need a method called `tagged`.
  Rails.logger = Shoryuken.logger
  ActiveRecord::Base.logger.formatter = Shoryuken.logger.formatter

  # register all shoryuken middleware
  config.server_middleware do |chain|
    chain.add JobMonitoringMiddleware
    chain.add JobRequestStoreMiddleware
    chain.add JobSentryScopeMiddleware
  end
end
