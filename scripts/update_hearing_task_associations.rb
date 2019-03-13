# frozen_string_literal: true

def legacy_hearings_with_no_hearing_tasks(hearing_type)
  start_date = (hearing_type == "V") ? "2019-03-31" : "2019-01-14"

  hearings_post_april = VACOLS::CaseHearing
    .where("trunc(hearing_date) > ? and hearing_type = '#{hearing_type}' and hearing_disp is null", start_date)

  list_of_folder_nr = hearings_post_april.pluck(:folder_nr)
  legacy_appeals = LegacyAppeal.where(vacols_id: list_of_folder_nr)
  hearing_tasks = HearingTask.where(appeal: legacy_appeals).includes(:appeal)

  hearing_tasks_folder_nrs = hearing_tasks.map do |hearing_task|
    hearing_task.appeal.vacols_id
  end

  hearings_without_hearing_tasks = list_of_folder_nr - hearing_tasks_folder_nrs

  create_these_hearings = hearings_post_april.where(folder_nr: hearings_without_hearing_tasks)

  create_hearing_tasks_tree_for(create_these_hearings)
end

def create_hearing_tasks_tree_for(vacols_records)
  count = 0

  vacols_records.each do |hearing|
    legacy_hearing = LegacyHearing.assign_or_create_from_vacols_record(hearing)

    root_task = RootTask.find_or_create_by!(
      appeal: legacy_hearing.appeal
    )

    hearing_task = HearingTask.create_by(
      appeal: legacy_hearing.appeal,
      assigned_to: Bva.singleton,
      parent: root_task
    )

    disposition_task = DispositionTask.create_disposition_task!(
      legacy_hearing.appeal, hearing_task, legacy_hearing
    )

    AppealRepository.update_location!(legacy_hearing.appeal, LegacyAppeal::LOCATION_CODES[:caseflow])

    puts "created hearing task: #{hearing_task.id} and disposition task: #{disposition_task.id}
          for legacy_appeal #{hearing.appeal.id}"
    count += 1
  end

  puts "created #{count} hearing tasks"
end

def update_non_existent_hearing_task_associations
  appeal_ids = HearingTask.where(appeal_type: "legacy_appeal")
    .joins("legacy_appeals ON legacy_appeals.id = tasks.appeal_id")
    .select("legacy_appeals.vacols_id").map { |a| a.vacols_id }

  unassociated_hearings = VACOLS::CaseHearing.where(folder_nr: appeal_ids, hearing_disp: nil)
end

def update_stale_hearing_task_associations
  hearing_task_associations = HearingTaskAssociation.all

  legacy_hearing_ids = hearing_task_associations.pluck(:hearing_id)
  vacols_ids = LegacyHearing.where(id: legacy_hearing_ids).pluck(:vacols_id)

  postponed_vacols_hearings = VACOLS::CaseHearing.where(hearing_disp: "P", hearing_pkseq: vacols_ids)
    .order("hearing_date")

  new_vacols_hearings = VACOLS::CaseHearing.where(
    folder_nr: postponed_vacols_hearings.pluck(:folder_nr), hearing_disp: nil
  )

  new_hearing_task_hearings = new_vacols_hearings.map do |hearing|
    LegacyHearing.assign_or_create_from_vacols_record(hearing)
  end

  new_hearing_task_hearings.each do |hearing|
    hearing_task = HearingTask.find_by(appeal: hearing.appeal)
    fail if hearing_task.nil?

    old_hearing = hearing_task.hearing_task_association.hearing

    hearing_task.hearing_task_association.update(hearing: hearing)

    puts "update hearing task #{hearing_task.id} association from #{old_hearing&.id} to #{hearing.id}"
  end
end
