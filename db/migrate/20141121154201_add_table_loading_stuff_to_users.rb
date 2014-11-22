class AddTableLoadingStuffToUsers < ActiveRecord::Migration
  def change
    add_column :users, :progress_message, :text
    add_column :users, :table_progress, :float
    add_column :users, :table_ready, :boolean
    add_column :users, :table, :text
  end
end
