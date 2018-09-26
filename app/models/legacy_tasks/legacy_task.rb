class LegacyTask
  include ActiveModel::Model
  include ActiveModel::Serialization

  ATTRS = [:id, :appeal_id, :assigned_to, :due_on, :assigned_at, :docket_name, :previous_task,
           :docket_date, :added_by, :task_id, :action, :document_id, :assigned_by, :work_product].freeze

  attr_accessor(*ATTRS)
  attr_writer :appeal

  ### Serializer Methods Start
  def assigned_on
    assigned_at
  end

  delegate :css_id, :name, to: :added_by, prefix: true
  delegate :first_name, :last_name, :pg_id, :css_id, to: :assigned_by, prefix: true

  def user_id
    assigned_to && assigned_to.css_id
  end

  def assigned_to_pg_id
    assigned_to && assigned_to.id
  end

  def assigned_by_name
    FullName.new(assigned_by_first_name,
                 "",
                 assigned_by_last_name)
    .formatted(:readable_full)
  end

  def appeal
    @appeal ||= LegacyAppeal.find(appeal_id)
  end

  def appeal_type
    appeal.class.name
  end

  def attorney_case_reviews
    QueueRepository.tasks_for_appeal(appeal.vacols_id).reject { |t| t.document_id.nil? }
  end

  def days_waiting
    (Date.today - assigned_at.to_date).to_i if assigned_at
  end

  ### Serializer Methods End

  def self.from_vacols(record, appeal, user)
    new(
      id: record.vacols_id,
      due_on: record.date_due,
      docket_name: "legacy",
      added_by: record.added_by,
      docket_date: record.docket_date.try(:to_date),
      appeal_id: appeal.id,
      assigned_to: user,
      assigned_at: record.assigned_to_location_date.try(:to_date),
      task_id: record.created_at ? record.vacols_id + "-" + record.created_at.strftime("%Y-%m-%d") : nil,
      document_id: record.document_id,
      assigned_by: record.assigned_by,
      appeal: appeal
    )
  end

  def self.repository
    @repository ||= QueueRepository
  end
end
