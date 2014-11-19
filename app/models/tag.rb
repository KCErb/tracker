class Tag < ActiveRecord::Base
  has_many :tag_histories, dependent: :destroy
  has_many :members, through: :tag_histories
  has_many :households, through: :tag_histories
end
