module Caseflow::Error
  class SerializableError < StandardError
    attr_accessor :code, :message

    def initialize(args)
      @code = args[:code]
      @message = args[:message]
    end

    def serialize_response
      { json: { "errors": [{ "status": code, "title": message, "detail": message }] }, status: code }
    end
  end

  class EfolderError < SerializableError; end
  class DocumentRetrievalError < EfolderError; end
  class EfolderAccessForbidden < EfolderError; end
  class ClientRequestError < EfolderError; end

  class ActionForbiddenError < SerializableError
    def initialize(args)
      @code = args[:code] || 403
      @message = args[:message] || "Action forbidden"
    end
  end

  class NoRootTask < SerializableError
    def initialize(args)
      @task_id = args[:task_id]
      @code = args[:code] || 500
      @message = args[:message] || "Could not find root task for task with ID #{@task_id}"
    end
  end

  class BvaDispatchTaskCountMismatch < SerializableError
    # Add attr_accessors for testing
    attr_accessor :user_id, :appeal_id, :tasks

    def initialize(args)
      @user_id = args[:user_id]
      @appeal_id = args[:appeal_id]
      @tasks = args[:tasks]
      @code = args[:code] || 400
      @message = args[:message] || "Expected 1 BvaDispatchTask received #{@tasks.count} tasks for"\
                                   " appeal #{@appeal_id}, user #{@user_id}"
    end
  end

  class BvaDispatchDoubleOutcode < SerializableError
    attr_accessor :task_id, :appeal_id

    def initialize(args)
      @appeal_id = args[:appeal_id]
      @task_id = args[:task_id]
      @code = args[:code] || 400
      @message = args[:message] || "Appeal #{@appeal_id}, task ID #{@task_id} has already been outcoded. "\
                                   "Cannot outcode the same appeal and task combination more than once"
    end
  end

  class DuplicateOrgTask < SerializableError
    attr_accessor :appeal_id, :task_type, :assignee_type

    def initialize(args)
      @appeal_id = args[:appeal_id]
      @task_type = args[:task_type]
      @assignee_type = args[:assignee_type]
      @code = args[:code] || 500
      @message = args[:message] || "Appeal #{@appeal_id} already has an active task of type #{@task_type} assigned to "\
                                   "#{assignee_type}. Cannot create a duplicate task for this organization"
    end
  end

  class OutcodeValidationFailure < SerializableError
    def initialize(args)
      @code = args[:code] || 400
      @message = args[:message]
    end
  end

  class DocumentUploadFailedInVBMS < SerializableError
    def initialize(args)
      @code = args[:code] || 502
      @message = args[:message]
    end
  end

  class TooManyChildTasks < SerializableError
    def initialize(args)
      @task_id = args[:task_id]
      @code = args[:code] || 500
      @message = args[:message] || "JudgeTask #{@task_id} has too many children"
    end
  end

  class ChildTaskAssignedToSameUser < SerializableError
    def initialize
      @code = 500
      @message = "A task cannot be assigned to the same user as the parent."
    end
  end

  class MultipleAppealsByVBMSID < StandardError; end
  class CertificationMissingData < StandardError; end
  class InvalidSSN < StandardError; end
  class InvalidFileNumber < StandardError; end
  class MustImplementInSubclass < StandardError; end
  class AttributeNotLoaded < StandardError; end

  class EstablishClaimFailedInVBMS < StandardError
    attr_reader :error_code

    def initialize(error_code)
      @error_code = error_code
    end

    def self.from_vbms_error(error)
      case error.body
      when /PIF is already in use/
        DuplicateEp.new("duplicate_ep")
      when /A duplicate claim for this EP code already exists/
        DuplicateEp.new("duplicate_ep")
      when /The PersonalInfo SSN must not be empty./
        new("missing_ssn")
      when /The PersonalInfo.+must not be empty/
        new("bgs_info_invalid")
      when /The maximum data length for AddressLine1/
        LongAddress.new("long_address")
      else
        error
      end
    end
  end

  class DuplicateEp < EstablishClaimFailedInVBMS; end
  class LongAddress < EstablishClaimFailedInVBMS; end

  class VacolsRepositoryError < StandardError; end
  class VacolsRecordNotFound < VacolsRepositoryError; end
  class UserRepositoryError < VacolsRepositoryError; end
  class IssueRepositoryError < VacolsRepositoryError; end
  class QueueRepositoryError < VacolsRepositoryError; end
  class MissingRequiredFieldError < VacolsRepositoryError; end

  class IdtApiError < StandardError; end
  class InvalidOneTimeKey < IdtApiError; end
end
