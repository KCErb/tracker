class TagHistory < ActiveRecord::Base
  belongs_to :member
  belongs_to :tag
  serialize :added_by, Array
  serialize :added_at, Array
  serialize :removed_by, Array
  serialize :removed_at, Array

  def active?
    case
    when added_at.length > 0 && removed_at.length > 0
      added_at.last > removed_at.last
    when added_at.length > 0
      true
    else
      false
    end
  end
end
