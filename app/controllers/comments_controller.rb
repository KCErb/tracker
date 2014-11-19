class CommentsController < ApplicationController

  respond_to :html, :js

  def create
    if params[:household_id]
      @moh = Household.find(params[:household_id])
      @moh_prev_unknown = !@moh.known?
    else
      @moh = Member.find(params[:member_id])
      @moh_prev_unknown = !@moh.household.known?
    end

    if comment_params[:body].squish != ""
      @comment = Comment.new(comment_params)
      if comment_params["created_at(1i)"]
        # create your own creation date!
        somedate = Date.parse(comment_params["created_at(1i)"] + "-" +
                              comment_params["created_at(2i)"] + "-" +
                              comment_params["created_at(3i)"])
                              @comment.created_at = somedate.to_datetime
      end
      @comment.viewed_by << current_user.lds_id
      @comment.save
      @moh.comments << @comment #autosaves

      respond_with( @moh, :layout => !request.xhr? )
    else #no blank comments!
      @moh = false
      respond_with( @moh, :layout => !request.xhr? )
    end
  end

  def destroy
    if params[:household_id]
      @moh = Household.find(params[:household_id])
    else
      @moh = Member.find(params[:member_id])
    end
    @comment = @moh.comments.find(params[:id])
    @comment.destroy
    # create.js.coffee already does what I want! So the name is a little off.
    respond_to do |format|
      format.js { render action: "create"}
    end
  end

  def create_edit_box
    if params[:household_id]
      @moh = Household.find(params[:household_id])
    else
      @moh = Member.find(params[:member_id])
    end
    @comment = Comment.find(params[:id])
    respond_to{|format| format.js }
  end

  def cancel_edit_comment
    if params[:household_id]
      @moh = Household.find(params[:household_id])
    else
      @moh = Member.find(params[:member_id])
    end
    @comment = Comment.find(params[:id])
    # create.js.coffee already does what I want! So the name is a little off.
    respond_to do |format|
      format.js { render action: "create"}
    end
  end

  def edit
    if params[:household_id]
      @moh = Household.find(params[:household_id])
    else
      @moh = Member.find(params[:member_id])
    end
    @comment = Comment.find(params[:id])
    @comment.update(comment_params)
    respond_to do |format|
      format.js { render action: "create"}
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :commenter_name, :commenter_calling, :commenter_lds_id, :member_id, :household_id, :private, "created_at(1i)", "created_at(2i)", "created_at(3i)")
  end

end
