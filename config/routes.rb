Rails.application.routes.draw do

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'welcome#index'
  resources :sessions
  resources :users
  resources :members do
    resources :comments
  end
  resources :households do
    resources :comments
  end

  resources :tags
  resources :tag_histories

  get "/member_modal" => "members#member_modal", :as => "member_modal"
  get "/household_modal" => "households#household_modal", :as => "household_modal"

  get "/household_address" => "households#household_address", :as => "household_address"
  get "/member_address" => "members#member_address", :as => "member_address"

  patch "/update_tag_history" => "tag_histories#update", :as => "update_tag_history"

  patch "/update_filters" => "users#update_filters", :as => "update_filters"

  get "/update_table" => "users#update_filters", :as => "update_table"
  get "/create_table" => "sessions#create_table", :as => "create_table"

  get "/create_edit_box" => "comments#create_edit_box", :as => "create_edit_box"
  get "/cancel_edit_comment" => "comments#cancel_edit_comment", :as => "cancel_edit_comment"

  get "/create_tags_dialog" => "tags#create_dialog", :as => "create_tags_dialog"
  get "/edit_tags_dialog" => "tags#edit_dialog", :as => "edit_tags_dialog"

end
