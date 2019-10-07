# frozen_string_literal: true

class DocumentsTag < ApplicationRecord
  belongs_to :document
  belongs_to :tag

  has_paper_trail save_changes: false, on: [:update, :destroy]
end
