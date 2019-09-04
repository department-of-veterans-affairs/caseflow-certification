# frozen_string_literal: true

class JudgeLegacyDecisionReviewTask < JudgeLegacyTask
  def review_action
    if Constants::DECASS_WORK_PRODUCT_TYPES["OMO_REQUEST"].include?(work_product)
      Constants.TASK_ACTIONS.ASSIGN_OMO.to_h
    else
      Constants.TASK_ACTIONS.JUDGE_LEGACY_CHECKOUT.to_h
    end
  end

  def available_actions(current_user, _role)
    return [] if current_user.vacols_roles.none? { |vrole| vrole.casecmp("judge").zero? } || current_user != assigned_to

    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      review_action
    ]
  end

  def label
    COPY::JUDGE_DECISION_REVIEW_TASK_LABEL
  end
end
