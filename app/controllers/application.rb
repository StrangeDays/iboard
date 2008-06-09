# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'gettext/rails'


class ApplicationController < ActionController::Base
  include IboardLibrary
  include ApplicationHelper

  helper :all # include all helpers, all the time
  helper_method :get_language_code, :user, :logged_id?, :granted_for?, :random_string

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd6a9006883e54593d3dd73129a1da8d3'
  
  before_filter :init_locale
  init_gettext(APPLICATION_NAME)
  GetText.bindtextdomain(APPLICATION_NAME,DEFAULT_LANGUAGE)
  
  def init_locale
    GetText.locale = get_language_code
  end
  
  def authenticate    
    ok = false
    if not user.nil?
      if user.utok == session[:utok]
        req = (root_path == "/") ? request.request_uri.gsub(/^\/(.*)/,'\1') : request.request_uri.gsub(root_path,"")
        req.gsub!(/^(.*)\?(.*)$/,'\1')
        ctl = req.split("/")[0]
        ok = granted_for?(ctl) || user.id==0 || req == "users/#{user.id}/welcome" || req == "newsletter_subscriptions/subscribe"
        if not ok
          flash[:error] = _('Permition denied to <em>%{ctl}-controller</em> for <em>%{user}</em>') % 
            {:ctl => ctl, :user => user.longname}
          flash[:error]+= "<br />" + _('Please log in with an authorized user')
        end
      end
    end
    if not ok
      session[:initial_uri] = request.request_uri
      flash[:notice] = _('Please log in')
      redirect_to :controller => "authenticate", :action => "login"
    end 
  end
  
  def set_language
    url = params[:back_to].gsub(/:/,"/")
    cookies[:language_code] = params[:code]
    flash[:notice] = _('Language changed to %{language}') % { :language => params[:code] }
    
    GetText.locale = params[:code]
    WillPaginate::ViewHelpers.pagination_options[:prev_label] = _('&laquo; Previous')
    WillPaginate::ViewHelpers.pagination_options[:next_label] = _('Next &raquo;')    
    redirect_to root_path
  end

  public
  def get_language_code
    rc = ""
    if cookies[:language_code]
      rc = cookies[:language_code]
    else
      rc = DEFAULT_LANGUAGE
      cookies[:language_code] = rc
    end
    rc
  end
  
  def user
    if session[:user]
      @session_user ||= User.find(session[:user])
    else
      nil
    end
  end
   
end



