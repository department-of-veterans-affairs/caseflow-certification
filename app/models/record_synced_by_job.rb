# frozen_string_literal: true

class RecordSyncedByJob < ApplicationRecord
  belongs_to :record, polymorphic: true

  def self.next_records_to_process(records, limit)
    records.includes(:record_synced_by_job)
      .order("record_synced_by_jobs.processed_at").limit(limit)
  end
end
