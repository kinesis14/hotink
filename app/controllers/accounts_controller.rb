class AccountsController < ApplicationController
  
  skip_before_filter :find_account
  skip_before_filter :verify_authenticity_token
  before_filter :clear_flash

  skip_before_filter :login_required, :only => [:new, :create]
  before_filter :ensure_no_accounts, :only => [:new, :create]  
  layout 'login', :only => [:new, :create]
  
  # Root account creation
  # ---------------------
  # Both the #new and #create actions are reserved for creating the root account
  # during installation
  def new
    @account = Account.new
    @user = User.new
    render :template => "accounts/first_account_form"
  end

  def create
    @account = Account.new(params[:account])
    @user = User.new(params[:user])  

    ActiveRecord::Base.transaction do
      @account.save!
      @user.save!
    end
    
    @user.has_role "admin"
    @account.accepts_role "manager", @user # Gives admin control over account
    @account.accepts_role "staff", @user # Makes user a staff member of the account
    
    flash[:notice] = "Welcome to Hot Ink!"
    redirect_to account_articles_url(@user.account) 
    
    rescue ActiveRecord::RecordInvalid => invalid
      # TODO: below is a hack to fix broken transaction above (why isn't the transaction working?!)
      unless @account.new_record?
        @account.destroy
        @account = Account.new(params[:account])
      end
      render :action=>"accounts/first_account_form", :layout=>'login'
      return       
  end
  
  # Simple redirect to account articles page
  def index
    redirect_to account_articles_url( current_user.is_staff_for_what.first )
  end

  def show
    @account = Account.find(params[:id])    
    redirect_to account_articles_url( @account )
  end
  
  # Loads the account management tab
  def edit
    @account = Account.find(params[:id])
    permit "manager of :account or admin" do    
      if permit? "admin" 
        @accounts = Account.find(:all) 
      end
      
      respond_to do |format|
        format.js
      end
    end
  end

  # PUT /accounts/1
  def update
    @account = Account.find(params[:id])
    permit "manager of :account or admin" do  
      respond_to do |format|
        if @account.update_attributes(params[:account])
          flash[:notice] = "Account updated"
          format.html { redirect_to(account_articles_url(@account)) }
          format.js   { head :ok }
        else
          format.html { render :action => "edit", :status => :bad_request }
        end
      end
    end
  end

  private
  
  def ensure_no_accounts
    unless Account.all.empty?
      render :text => "Page not found", :status => :not_found
      false
    end
  end
end



