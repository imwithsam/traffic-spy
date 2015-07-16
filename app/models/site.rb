class Site < ActiveRecord::Base
  validates :identifier, presence: true, uniqueness: true
  validates_presence_of :root_url

  has_many :urls
end