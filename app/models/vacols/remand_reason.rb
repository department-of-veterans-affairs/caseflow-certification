class VACOLS::RemandReason < VACOLS::Record
  # :nocov:
  self.table_name = "vacols.rmdrea"

  class RemandReasonError < StandardError; end

  CODES = Constants::ACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys).concat(
    Constants::INACTIVE_REMAND_REASONS_BY_ID.values.flat_map(&:keys)
  ).freeze

  validates :rmdkey, :rmdissseq, :rmdval, :rmddev, :rmdmdusr, :rmdmdtim, presence: true, on: :create
  validates :rmdval, inclusion: { in: CODES }

  def self.create_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    (remand_reasons || []).each { |remand_reason| create!(remand_reason.merge(rmdkey: rmdkey, rmdissseq: rmdissseq)) }
  end

  def self.load_remand_reasons(rmdkey, rmdissseq)
    where(rmdkey: rmdkey, rmdissseq: rmdissseq)
  end

  def self.delete_remand_reasons!(rmdkey, rmdissseq)
    load_remand_reasons(rmdkey, rmdissseq).delete_all
  end

  def self.update_remand_reasons!(rmdkey, rmdissseq, remand_reasons)
    load_remand_reasons(rmdkey, rmdissseq).map.with_index do |reason, idx|
      updated_reason = remand_reasons[idx].merge(rmdkey: rmdkey, rmdissseq: rmdissseq)
      reason.update_attributes!(updated_reason)
    end
  end

  def update(*)
    update_error_message
  end

  def update!(*)
    update_error_message
  end

  def delete
    delete_error_message
  end

  def destroy
    delete_error_message
  end

  private

  def update_error_message
    fail RemandReasonError, "Since the primary key is not unique, `update` will update all results
      with the same `rmdkey`. Instead use VACOLS::RemandReason.update_remand_reasons! that uses `rmdkey`
      and `rmdissseq` to safely update one record"
  end

  def delete_error_message
    fail RemandReasonError, "Since the primary key is not unique, `delete` or `destroy` will delete
      all results with the same `rmdkey`. Instead use VACOLS::RemandReason.delete_remand_reasons! that uses
      `rmdkey` and `rmdissseq` to safely delete one record"
  end
  # :nocov:
end
