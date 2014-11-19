class HouseholdsController < ApplicationController

  def index
    @household = Household.find_by_lds_id(params[:lds_id])
    respond_to do |format|
      format.json { render json: @household }
    end
  end

  def household_modal
    @household = Household.find_by_lds_id(params[:lds_id])
    @household.comments.all.each do |comment|
      next if comment.viewed_by.include? current_user.lds_id
      comment.viewed_by << current_user.lds_id
      comment.save
    end
    respond_to{|format| format.js }
  end

  def household_address
    @household = Household.find_by_lds_id(params[:lds_id])
    cookies = session[:user_pref]
    @scraper = Scraper.new(cookies)
    @address = @scraper.get_address(@household.lds_id)
    respond_to{|format| format.js }
  end
end
