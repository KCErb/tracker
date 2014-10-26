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
    @comment = @member.comments.create(comment_params)
    respond_with( @member, :layout => !request.xhr? )
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :commenter_name, :commenter_calling, :member_id)
  end

end
