class TagsController < ApplicationController
  def create
    @tag = Tag.create(tag_params)
    respond_to{|format| format.js }
  end

  def create_dialog
    @tag = Tag.new
    respond_to{|format| format.js }
  end

  def edit_dialog
    @tag = Tag.find(params[:id])
    respond_to{|format| format.js }
  end

  def update
    @tag = Tag.find(params[:id])
    @tag.update(tag_params)
    respond_to{|format| format.js }
  end

  def destroy
    @tag = Tag.find(params[:id])
    @tag.destroy
    redirect_to sessions_path
  end

  private

  def tag_params
    params.require(:tag).permit(:body, :organization, :color)
  end
end
