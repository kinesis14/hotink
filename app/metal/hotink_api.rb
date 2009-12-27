# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)
require 'sinatra/base'

class HotinkApi < Sinatra::Base
  
  def load_account
    @account = Account.find(params[:account_id])
  end
  
  get "/accounts/:account_id/articles.xml" do
    load_account
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    
    if params[:ids]
      @articles = @account.articles.published.all(:conditions => { :id => params[:ids] })
    elsif params[:section_id]
      @articles = @account.articles.by_published_at(:desc).paginate(:page => page, :per_page => per_page, :conditions => { :section_id => params[:section_id] }) 
    elsif params[:tagged_with]
      @articles = @account.articles.published.by_published_at(:desc).tagged_with(params[:tagged_with], :on => :tags).paginate( :page=> page, :per_page => per_page )
    elsif params[:search]
      @articles = @account.articles.published.search( params[:search], :page => page, :per_page => per_page)
    else
      @articles = @account.articles.published.by_date_published(:desc).paginate(:page => page, :per_page => per_page)
    end
    
    content_type "text/xml"
    @articles.to_xml    
  end
  
  get "/accounts/:account_id/articles/:id.xml" do
    load_account    
    begin
      @article = @account.articles.published.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      halt 404, "Record not found or unavailable."
    end

    content_type "text/xml"
    @article.to_xml
  end
  
  get "/accounts/:account_id/issues.xml" do
    load_account
    page = params[:page] || 1
    per_page = params[:per_page] || 15
    
    @issues = @account.issues.processed.paginate(:page => page, :per_page => per_page, :order => "date DESC")
    
    content_type "text/xml"
    @issues.to_xml
  end
  
  get "/accounts/:account_id/issues/:id.xml" do
    load_account    
    begin
      @issue = @account.issues.processed.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      halt 404, "Record not found or unavailable."
    end
    content_type "text/xml"
    @issue.to_xml
  end
  
  get "/accounts/:account_id/issues/:id/articles.xml" do
    load_account    

    begin
      @issue = @account.issues.find(params[:id])
    rescue ActiveRecord::RecordNotFound => e
      halt 404, "Record not found or unavailable."
    end
    
    if params[:section_id]
      begin
        @section = @account.categories.find(params[:section_id]) if params[:section_id]
      rescue
        @articles = []
      else
        @articles = @issue.articles.published.in_section(@section).by_date_published.all
      end
    else
      @articles = @issue.articles.published.by_date_published.all
    end
    
    content_type "text/xml"
    @articles.to_xml
  end
  
  get "/accounts/:account_id/sections.xml" do
    load_account
    
    @sections = @account.categories.active.sections.all
    
    content_type "text/xml"
    @sections.to_xml
  end
end
