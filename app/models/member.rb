class Member < ActiveRecord::Base
  belongs_to :household

  has_many :comments, dependent: :destroy
  has_many :tag_histories, dependent: :destroy
  has_many :tags, through: :tag_histories

  serialize :organizations, Array

  def active_tags
    active_tag_histories = tag_histories.find_all{|tag_history| tag_history.active?}
    active_tag_histories.map{|th| th.tag }
  end

  def known_tags
    tags.find_all{|tag| tag.organization == 'All'}
  end

  def timeline_data
    #pair elements with times. This seems silly for comments, but tags
    #have histories and we need to sort it all chronologically.
    timeline_data = []

    comments.each do |comment|
      timeline_data << [comment.created_at, comment]
    end

    tag_histories.each do |tag_history|
      tag_history.added_at.each_with_index do |time, index|
        timeline_data << [time, tag_history.added_by, "added", tag_history, index]
      end
      tag_history.removed_at.each_with_index do |time, index|
        timeline_data << [time, tag_history.removed_by, "removed", tag_history, index]
      end
    end

    timeline_data.sort!{|a,b| a[0] <=> b[0] }
  end
end
