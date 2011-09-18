class Task < ActiveRecord::Base

  belongs_to :story
  validates_presence_of :story_id
end