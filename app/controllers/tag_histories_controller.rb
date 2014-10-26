class TagHistoriesController < ApplicationController
  respond_to :js
  def update
    @tag = Tag.find(params[:tag_id])
    @member = Member.find(params[:member_id])

    @tag_history = TagHistory.where(tag_id: params[:tag_id], member_id: params[:member_id])

    if @tag_history.length > 0
      @tag_history = @tag_history.first
    else
      @tag_history = TagHistory.new( tag_id: params[:tag_id],
                                     member_id: params[:member_id])
    end

    @tag_history.added_by << params[:added_by] if params[:added_by]
    @tag_history.added_at << params[:added_at] if params[:added_at]
    @tag_history.removed_by << params[:removed_by] if params[:removed_by]
    @tag_history.removed_at << params[:removed_at] if params[:removed_at]
    
    @tag_history.save

    respond_with(@member, @tag, :layout => !request.xhr? )
  end
end
