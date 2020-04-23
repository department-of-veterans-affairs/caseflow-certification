# frozen_string_literal: true

module CssIdConcern
  extend ActiveSupport::Concern

  # :reek:UtilityFunction
  def invalid_css_id?(css_id)
    css_id =~ /[a-z]/
  end

  def normalize_css_id(css_id)
    css_id&.upcase
  end
end
