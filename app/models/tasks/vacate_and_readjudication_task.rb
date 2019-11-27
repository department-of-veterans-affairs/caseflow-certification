# frozen_string_literal: true

class VacateAndReadjudicationTask < DecidedMotionToVacateTask
  def self.label
    COPY::VACATE_AND_READJUDICATION_TASK_LABEL
  end

  def self.org(user)
    JudgeTeam.for_judge(user.reload)
  end
end
