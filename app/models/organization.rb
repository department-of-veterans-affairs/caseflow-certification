class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to

  def user_has_access?(user)
    false
  end
end
