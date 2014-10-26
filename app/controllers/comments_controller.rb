class CommentsController < ApplicationController

  respond_to :html, :js

  def index
    puts "running index"
    @member = Member.find(params[:member_id])
    @comments = @member.comments

    respond_to do |format|
      format.html { render @comments }
      format.json { render json: @comments }
    end
  end

  def create
    @member = Member.find(params[:member_id])
    if comment_params[:body].squish != ""
      @comment = @member.comments.create(comment_params)
      somedate = Date.parse(comment_params["created_at(1i)"] + "-" +
                            comment_params["created_at(2i)"] + "-" +
                            comment_params["created_at(3i)"])
      @comment.created_at = somedate.to_datetime
      @comment.save
      respond_with( @member, :layout => !request.xhr? )
    else
      @member = false
      respond_with( @member, :layout => !request.xhr? )
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :commenter_name, :commenter_calling, :member_id, "created_at(1i)", "created_at(2i)", "created_at(3i)")
  end

end
