class Tag < ActiveRecord::Base
  has_many :tag_histories
  has_many :tags, through: :tag_histories
end
