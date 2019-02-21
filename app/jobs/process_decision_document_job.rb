class ProcessDecisionDocumentJob < CaseflowJob
  queue_as :low_priority
  application_attr :intake

  def perform(decision_document_id)
    RequestStore.store[:application] = "idt"
    RequestStore.store[:current_user] = User.system_user

    DecisionDocument.find(decision_document_id).process!
  end
end
