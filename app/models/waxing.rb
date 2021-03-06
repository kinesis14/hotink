class Waxing < ActiveRecord::Base
  belongs_to :account
  
  belongs_to :mediafile
  validates_presence_of :mediafile
  
  belongs_to :document
  validates_presence_of :document
  belongs_to :article, :class_name => "Article", :foreign_key => "document_id"
end
