class StartDistributionJob < ApplicationJob
  queue_as :high_priority
  application_attr :queue

  def perform(distribution, user = nil)
    RequestStore.store[:current_user] = user if user
    distribution.distribute!
  rescue StandardError => e
    Rails.logger.info "StartDistributionJob failed: #{e.message}"
    Rails.logger.info e.backtrace.join("\n")
  end

  def max_attempts
    1
  end
end
