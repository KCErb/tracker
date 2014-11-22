class UsersController < ApplicationController
  respond_to :js

  def update_filters
    case params[:type]
    when "known"
      current_user.filters[:known] = current_user.filters[:known] ? false : true
    when "unknown"
      current_user.filters[:unknown] = current_user.filters[:unknown] ? false : true
    when "unread"
      current_user.filters[:unread] = current_user.filters[:unread] ? false : true
    when "tags"
      tags = current_user.filters[:tags].split(";")
      if tags.any?{|tag| tag == params[:body]}
        tags.delete(params["body"])
      else
        tags << params[:body]
      end
      current_user.filters[:tags] = tags.join(";")
    when "organization"
      if current_user.filters[:organization] == params[:organization]
        current_user.filters[:organization] = ""
      else
        current_user.filters[:organization] = params[:organization]
      end
    when "search"
      current_user.filters[:search] = params[:search_text]
    else
      #This can be called just to re-edit the table
    end
    current_user.save

    @filters = current_user.filters.to_json.html_safe
    respond_with( @filters, :layout => !request.xhr? )
  end

  def init_polling
    respond_to{|format| format.js }
  end

  def check_status
    @user = current_user
    @stats = {progress: @user.table_progress, finished: @user.table_ready, message: @user.progress_message}
    respond_to do |format|
      format.json { render json: @stats }
    end
  end
end
