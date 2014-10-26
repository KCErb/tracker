class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  force_ssl unless ENV["RAILS_ENV"] == "development"
  helper_method :current_user
  before_action :require_login

  private
  def current_user
    @current_user ||= User.find_by_lds_id(session[:id]) if session[:id]
  end

  def require_login
    if session[:id]
      user = User.find_by_lds_id(session[:id])
    end
    unless user
      flash[:notice] = "You are not logged in."
      redirect_to root_url
    end
  end
end
