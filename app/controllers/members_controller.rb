class MembersController < ApplicationController

  def index
    @member = Member.find_by_lds_id(params[:lds_id])
    respond_to do |format|
      format.json { render json: @member }
    end
  end

  def member_modal
    @member = Member.find_by_lds_id(params[:lds_id])
    @member.comments.find_each do |comment|
      next if comment.viewed_by.include? current_user.lds_id
      comment.viewed_by << current_user.lds_id
      comment.save
    end
    respond_to{|format| format.js }
  end

  def member_address
    @member = Member.find_by_lds_id(params[:lds_id])
    @household = @member.household
    cookies = session[:user_pref]
    @scraper = Scraper.new(cookies)
    @address = @scraper.get_address(@household.lds_id)
    respond_to{|format| format.js }
  end

end
