# Mediafile is an easy class to extend. But, if you do, rememeber to add support in:
#  - _edit_media_form.html.erb
#  - appropriate partials in app/views/mediafiles/article_form and app/views/mediafiles/entry_form
#  - appropriate display selector in _article_mediafiles.html.erb
#  - appropriate create selector in mediafiles_controller.rb
# 
# If support inserted in those for places, in addition to a new model file, it should
# work just fine.

class Mediafile < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  
  belongs_to :account
  
  has_many :waxings, :dependent => :destroy
  has_many :articles, :through => :waxings
  
  has_many :photocredits
  has_many :authors, :through => :photocredits
  
  validates_presence_of :account, :message => "must have an account"
  validates_associated :account, :message => "Account must be valid"
  
  accepts_nested_attributes_for :photocredits, :allow_destroy => true
  
  acts_as_taggable_on :tags
  
  has_attached_file :file,
      :path => ":rails_root/public/system/:account/:class/:id_partition/:basename_:style.:extension",
      :url => "/system/:account/:class/:id_partition/:basename_:style.:extension"
  
  before_create :set_date
  
  define_index do
    indexes title, :sortable => :true
    indexes file_file_name, :as => :file_name
    indexes file_content_type, :as => :content_type, :sortable => :true
    indexes file_file_size, :as => :file_size, :sortable => :true
    indexes description
    indexes authors.name, :as => :credits
    indexes tags.name, :as => :tags
    indexes date, :sortable => :true

    has created_at
    has account_id
    has type

    where "status = 'published'"
    
    set_property :delta => :delayed
  end
  
  def title
    title = self.read_attribute(:title)
    if title and title.strip != ""
      return title.strip
    elsif filename = self.read_attribute(:file_file_name)
      return filename
    else
      return "No file"
    end
  end
      
  # Returns list of article's author names as a readable list, separated by commas and the word "and".
  def authors_list
     case self.authors.length
     when 0
       return nil
     when 1
       return self.authors.first.name
     when 2
       return self.authors.first.name + " and " + self.authors.second.name
     else
      list = String.new
      (0..(self.authors.length - 3)).each{ |i| list += authors[i].name + ", " }
      list += authors[self.authors.length-2].name + " and " + authors[self.authors.length-1].name # last two authors get special formatting
      return list
    end         
  end

  #Breaks up a human readable list of authors and creates each one and adds it to self.authors.
  def authors_list=(list)
    if list
      list.split(/, and | and |,/).each do |name| 
        author = Author.find_or_create_by_name_and_account_id(name.strip, self.account.id)
        self.authors << author unless self.authors.member?(author) || author.nil?
      end
    end
  end
  
  def to_xml(options = {})
     caption = options[:caption] || self.description
     options[:indent] ||= 2
     xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
     xml.instruct! unless options[:skip_instruct]
     
     xml.mediafile do
       xml.tag!( :title, self.title )
       xml.tag!( :caption, caption)
       xml.tag!( :mediafile_type, self.type || "Mediafile" )
       xml.tag!( :date, self.date )
       xml.tag!( :authors_list, self.authors_list )
       xml.tag!( :url, self.file.url )
       xml.tag!( :content_type, self.file_content_type )
       xml.tag!( :original_file_size, number_to_human_size(self.file_file_size) )
       xml.tag!( :id, self.id )
     end
  end
  
  # A photocopy is an account neutral version of an mediafile, used to transfer between accounts
  def photocopy(new_account)
    copy = clone
    copy.account = new_account
    
    # Copy over associations
    authors.each { |a| copy.authors << a }
    copy.file = file
      
    copy.save ? copy : false
  end
  
  def date
    read_attribute(:date).to_date
  end
  
  def tag(new_tags)
    if self.tag_list.empty?
      self.tag_list = new_tags
    else
      self.tag_list = self.tag_list.to_s + ", #{new_tags}"
    end
  end
  
  private
  
  def set_date
    self.date = Date.today
  end
end
