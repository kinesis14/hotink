class Article < Document
  include ApplicationHelper
  
  has_one :checkout, :foreign_key => :duplicate_article_id, :dependent => :destroy
  has_one :pickup, :class_name => "Checkout", :foreign_key => :original_article_id
    
  named_scope :and_related_items, :include => [:authors, :mediafiles, :section]
  
  named_scope :in_section, lambda { |section| { :conditions => { :section_id => section.id } } }
     
  # A photocopy is an account neutral version of an article, used to transfer between accounts
  def photocopy(new_account)
    copy = clone
    
    # Remove account-specific attributes
    copy.account = new_account
    copy.section = nil
    copy.status = nil
    
    copy.save
    
    # has_many :through assocaitions can't be applied until the new record has been saved
    authors.each { |a| copy.authors << a }
    mediafiles.each do |m| 
      mediafile = m.photocopy(new_account)
      copy.mediafiles << mediafile 
    end
    
    copy.new_record? ? false : copy
  end
  
  def to_liquid
    {'title' => title, 'subtitle' => subtitle, 'authors_list' => authors_list, 'bodytext' => bodytext, 'excerpt' => excerpt, 'id' => id.to_s}
  end
  
  def excerpt
    return summary if summary
    truncate_words(bodytext)
  end

  # Article sign-off
  has_many :sign_offs
  named_scope :awaiting_attention, :joins  => 'INNER JOIN sign_offs ON sign_offs.article_id = documents.id', :group => 'documents.id', :conditions => { :status => "Awaiting attention" }
  
  def awaiting_attention?
    (self.status=='Awaiting attention') && !self.sign_offs.blank?
  end
  
  def signed_off_by?(user)
    !sign_offs.find_by_user_id(user).nil?
  end
  
  def sign_off(user)
    if draft? || awaiting_attention?
      self.status = "Awaiting attention"
      sign_offs.create(:user => user)
      true
    else
      false
    end
  end
  
  def revoke_sign_off(user)
    if awaiting_attention? && signed_off_by?(user)
      self.sign_offs.find_by_user_id(user.id).destroy
    end
    self.status = nil if self.sign_offs.reload.empty?
  end
  
  def is_editable_by
    if published? || scheduled?
      if published_at < 3.weeks.ago
        "(manager of account) or admin"
      else
        "(manager of account) or (editor of account) or admin"
      end
    else
      "(owner of article) or (editor of account) or (manager of account) or admin"
    end
  end
  
  def add_section_to_categories
    if section && !categories.include?(section)
      categories << section
    end
  end
  before_save :add_section_to_categories
  
  def tag(new_tags)
    if self.tag_list.empty?
      self.tag_list = new_tags
    else
      self.tag_list = self.tag_list.to_s + ", #{new_tags}"
    end
  end
end
