class MembersController < ApplicationController

  def index
    @member = Member.find_by_lds_id(params[:lds_id])
    respond_to do |format|
      format.json { render json: @member }
    end
  end

  def modal
    @member = Member.find_by_lds_id(params[:lds_id])
    respond_to{|format| format.js }
  end

  def member_info
    cookies = session[:user_pref]
    @scraper = Scraper.new(cookies)
    @scraper.get_member_info(params[:lds_id])
    @member_info = @scraper.member_info
    @member = Member.find_by_lds_id(params[:lds_id])
    respond_to{ |format| format.js }
  end

  def member_tags
    @member = Member.find_by_lds_id(params[:lds_id])
    respond_to do |format|
      format.js
    end
  end
end
