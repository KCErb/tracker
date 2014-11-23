#encoding utf-8
class SessionsController < ApplicationController
  skip_before_action :require_login, only: :create

  def index
  end

  def init_table
    cookies = session[:user_pref]
    scraper = Scraper.new(cookies)
    if scraper.session_still_valid?
      current_user.table_ready = false
      current_user.table_progress = 0.0
      current_user.progress_message = "Loading Data"
      current_user.table = ''
      current_user.save
      Thread.new do
        scraper.create_table
        ActiveRecord::Base.connection.close
      end
      respond_to{|format| format.js } #does nothing
    else
      flash[:notice] = "You're not logged in anymore."
      respond_to{|format| format.js {render :js => "window.location.href='/'"} }
    end
    scraper = nil
  end

  def create_table
    @table = current_user.table
    respond_to{|format| format.js}
    @table = nil
    current_user.table = ''
    current_user.save
    GC.start
  end

  def create
    @scraper = Scraper.new(params)
    params = nil
    handle_auth(@scraper.handle_auth)
  end

  def destroy
    session[:id] = nil
  end

  private

  def handle_auth(response)
    case response
    when :authorized
      @user = @scraper.user
      session[:id] = @user.lds_id
      cookies = @scraper.cookies
      session[:user_pref] = cookies
      redirect_to sessions_path
    when :wrong_ward
      flash[:notice] = "You're not a member of the 1st Ward."
      redirect_to root_url
    when :not_authorized
      flash[:notice] = "You don't have leadership privileges on lds.org."
      redirect_to root_url
    else
      flash[:notice] = "Invalid username or password."
      redirect_to root_url
    end
  end
end
