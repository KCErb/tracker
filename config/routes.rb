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
  resources :tags

  get "/member_modal" => "members#modal", :as => "member_modal"
  get "/member_info" => "members#member_info", :as => "member_info"
  get "/member_tags" => "members#member_tags", :as => "member_tags"
  patch "/update_member_tag" => "tag_histories#update", :as => "update_member_tag"
  patch "/update_filters" => "users#update_filters", :as => "update_filters"
  get "/update_table" => "users#update_filters", :as => "update_table"

end
