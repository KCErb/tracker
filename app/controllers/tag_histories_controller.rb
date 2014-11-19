class TagHistoriesController < ApplicationController
  #respond_to :js
  def update
    if params[:type] == 'household'
      fetch_household_tag
    else
      fetch_member_tag
    end

    @tag_history.added_by << params[:added_by] if params[:added_by]
    @tag_history.added_at << params[:added_at] if params[:added_at]
    @tag_history.removed_by << params[:removed_by] if params[:removed_by]
    @tag_history.removed_at << params[:removed_at] if params[:removed_at]

    @tag_history.save

    respond_to{|format| format.js }
    #respond_with(@member, @tag, :layout => !request.xhr? )
  end

  def destroy
    @tag_history = TagHistory.find(params[:id])

    index = params[:index].to_i
    if params[:changed] == 'added'
      @tag_history.added_by.delete_at(index)
      @tag_history.added_at.delete_at(index)
    else
      @tag_history.removed_at.delete_at(index)
      @tag_history.removed_by.delete_at(index)
    end
    if @tag_history.added_at == [] && @tag_history.removed_at == []
      @tag_history.destroy
      @tag_history_deleted = true
    else
      @tag_history.save
    end

    #re-create correct modal / timeline
    @member = @tag_history.member
    @household = @tag_history.household
    # update.js.coffee already does what I want, so just use it!
    respond_to do |format|
      format.js { render action: "update"}
    end
  end

  private

  def fetch_household_tag
    @household = Household.find(params[:moh_id])
    @household_prev_unknown = !@household.known?
    @tag_history = TagHistory.where(tag_id: params[:tag_id], household_id: params[:moh_id])

    if @tag_history.length > 0
      @tag_history = @tag_history.first
    else
      @tag_history = TagHistory.new( tag_id: params[:tag_id],
                                     household_id: params[:moh_id])
    end
  end

  def fetch_member_tag
    @member = Member.find(params[:moh_id])
    @member_prev_unknown = !@member.household.known?
    @tag_history = TagHistory.where(tag_id: params[:tag_id], member_id: params[:moh_id])

    if @tag_history.length > 0
      @tag_history = @tag_history.first
    else
      @tag_history = TagHistory.new( tag_id: params[:tag_id],
                                     member_id: params[:moh_id])
    end
  end
end
