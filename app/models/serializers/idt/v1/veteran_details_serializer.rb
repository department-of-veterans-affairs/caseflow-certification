# frozen_string_literal: true

class Idt::V1::VeteranDetailsSerializer
  include FastJsonapi::ObjectSerializer
  set_id do
    1
  end

  attribute :claimant do |object|
    {
      first_name: object[:first_name],
      last_name: object[:last_name],
      date_of_birth: object[:date_of_birth],
      date_of_death: object[:date_of_death],
      name_suffix: object[:name_suffix],
      sex: object[:sex],
      address_line1: object[:address_line1],
      country: object[:country],
      zip_code: object[:zip_code],
      state: object[:state],
      city: object[:city],
      file_number: object[:file_number],
      participant_id: object[:participant_id]
    }
  end

  attribute :poa do |_veteran, params|
    params[:poa]
  end

  def read_attribute_for_serialization(attr)
    object[attr.to_s]
  end
end
