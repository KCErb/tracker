class Comment < ActiveRecord::Base
  belongs_to :member
  belongs_to :household
  serialize :viewed_by, Array
end
