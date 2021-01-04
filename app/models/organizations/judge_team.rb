# frozen_string_literal: true

class JudgeTeam < Organization
  scope :pushed_priority_cases_allowed, -> { active.where(accepts_priority_pushed_cases: true) }

  class << self
    def for_judge(user)
      user.administered_teams.detect { |team| team.is_a?(JudgeTeam) && team.judge.eql?(user) }
    end

    def create_for_judge(user)
      fail(Caseflow::Error::DuplicateJudgeTeam, user_id: user.id) if JudgeTeam.for_judge(user)

      create!(name: user.css_id, url: user.css_id.downcase, accepts_priority_pushed_cases: true).tap do |org|
        OrganizationsUser.make_user_admin(user, org)
      end
    end
  end

  def judge
    admin
  end

  def attorneys
    non_admins
  end

  def admin
    admins.first
  end

  def can_receive_task?(_task)
    false
  end

  def selectable_in_queue?
    false
  end

  def serialize
    super.merge(name: judge.full_name.titleize)
  end
end
