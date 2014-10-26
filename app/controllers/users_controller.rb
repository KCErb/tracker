class UsersController < ApplicationController
  respond_to :js
  def update_filters
    case params[:type]
    when "known"
      current_user.filters[:known] = current_user.filters[:known] ? false : true
    when "unknown"
      current_user.filters[:unknown] = current_user.filters[:unknown] ? false : true
    when "tags"
      if current_user.filters[:tags].include? params[:body]
        current_user.filters[:tags].sub! params["body"], ''
      else
        current_user.filters[:tags] += params[:body] unless current_user.filters[:tags].include? params[:body]
      end
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
end
