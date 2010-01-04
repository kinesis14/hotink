class EntriesController < ApplicationController
  before_filter :find_blog
  
  layout 'hotink'
  
  def new
    @entry = @account.entries.build 

    # Check to see if the last entry created for this blog exists and is blank.
    # If so, redate it and serve it up instead of a new entry, to prevent
    # the data from becoming cluttered with abandoned entries.
    #
    # If the last entry was legit, save the fresh entry so it can have relationships 
   if last_blog_entry = @blog.entries.find(:last)
     if last_blog_entry.created_at == last_blog_entry.updated_at
        @entry = last_blog_entry
     else
        @entry.save
        @blog.entries << @entry
     end
   else
      @entry.save
      @blog.entries << @entry
   end
       
      respond_to do |format|
        if @entry.save 
          flash[:notice] = "New blog entry"
          format.html { redirect_to edit_account_blog_entry_url(@account, @blog, @entry) }
          format.xml  { render :xml => @entry }
        else
          flash[:notice] = "Error saving entry"
          format.html { redirect_to account_blog_url(@account, @blog) }
        end
      end
  end
  
  def edit
    @entry = @blog.entries.find(params[:id])
  end
  
  
  def index    
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    conditions = { :account_id => @account.id, :status => "published" }
    
    if @blog
      @entries = @blog.entries.paginate(:page => page, :per_page => per_page, :order => "published_at DESC", :conditions => conditions)
    else
      @entries = Entry.paginate(:page => page, :per_page => per_page, :order => "published_at DESC", :conditions => conditions)
    end
    
    respond_to do |format|
      format.xml do
        render :xml => @entries
      end
    end
  end
  
  
  def show
    @entry = @blog.entries.find(params[:id])
    
    respond_to do |format|
      format.xml {
        render :xml => @entry
      }
    end    
  end
  
  def update
    @entry = @blog.entries.find(params[:id])
      
    # Only touch published status if status is passed
    if params[:entry][:status]=="Published"
      
      if permit?("(manager of account) or (editor of blog) or (contributor to blog) or admin")
        # Should we schedule publishing on a custom date or immediately?
        # Rely on a "schedule" parameter to determine which.
        if params[:entry][:schedule] 
          schedule = params[:entry].delete(:schedule)
          @entry.schedule(Time.local(schedule[:year].to_i, schedule[:month].to_i, schedule[:day].to_i, schedule[:hour].to_i, schedule[:minute].to_i))
        else
          @entry.publish
        end
      end

    elsif params[:entry][:status]==""
      params[:entry][:status]=nil #To make sure an entry is upublished properly
    end
  
    respond_to do |format|
      if @entry.update_attributes(params[:entry])
        flash[:notice] = "Entry saved"
        @entry = @blog.entries.find(params[:id])
        format.js
        format.html { redirect_to(edit_account_blog_entry_path(@account, @blog, @entry)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @entry.errors, :status => :unprocessable_entity }
      end
    end
  end
  

  def destroy
    @entry = @blog.entries.find(params[:id])

    respond_to do |format|
      if @entry.destroy
        flash[:notice] = "Entry trashed"
        format.js
        format.html { redirect_to(account_blog_url(@account, @blog)) }
        format.xml  { head :ok }
      else
        flash[:notice] = "Entry couldn't be deleted"
      end
    end
  end
  
  private
  
  def find_blog
    if params[:blog_id]
      @blog = @account.blogs.find(params[:blog_id])
    else
      @blog = false
    end
  end
end
