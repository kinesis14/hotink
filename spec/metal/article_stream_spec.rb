require 'spec_helper'

class TestApp < Sinatra::Base
  enable :sessions
  use ArticleStream::App
end

describe ArticleStream do
  include Rack::Test::Methods
  include Webrat::Matchers
  
  before do
    @account = Factory(:account)      
    Account.stub!(:find).and_return(@account)
    
    @user = Factory(:user, :skip_session_maintenance => true)
  end
  
  def app
    TestApp
  end
  
  describe "GET to /stream/articles/:id" do
    before(:each) do
      @article = Factory(:detailed_article)
      get "/stream/articles/#{@article.id}"
    end
    
    it "should display the article details" do
      pending
      last_response.body.should include(@article.title)
      last_response.body.should include(@article.subtitle)
      last_response.body.should include(@article.authors_list)
      last_response.body.should include(@article.section)
      last_response.body.should include(@article.published_at.to_s(:standard))
      last_response.body.should include(Markdown.new(@article.bodytext).to_html)
    end
  end
  
  describe "GET to /team" do
    before(:each) do
      @users = (1..3).collect do |n|
        user = mock("team member")
        user.should_receive(:id).twice.and_return(n)
        user.should_receive(:name).and_return("Team Member ##{n}")
        user.should_receive(:email).and_return("team#{n}@testemail.com")
        user
      end
      @account.should_receive(:has_staff).and_return(@users)
      get "/team"
    end
    
    it "should show each team member" do
      pending
      @users.each do |u|
        last_response.body.should have_selector("#user_#{u.id}")
      end
    end
  end
  
end