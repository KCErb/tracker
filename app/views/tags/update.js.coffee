#Iterate through all households and update tags span
<% Household.find_each do |household| %>
<% if household.tags.count > 0 %>
household_tags = $("tr[data-row-type='household'][data-id=<%= household.lds_id =%>] td[class='table-tags']")
<% tag_html = "" %>
<% household.active_tags.each do |tag| %>
<% tag_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"%>
<% end %>
tagHTML = '<%= escape_javascript tag_html.html_safe %>'
household_tags.html(tagHTML)
<% end %>

<% household.members.each do |member| %>
<% if member.tags.count > 0 %>
member_tags = $("tr[data-row-type='member'][data-id=<%= member.lds_id =%>] td[class='table-tags']")
<% tag_html = "" %>
<% member.active_tags.each do |tag| %>
<% tag_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"%>
<% end %>
tagHTML = '<%= escape_javascript tag_html.html_safe %>'
member_tags.html(tagHTML)
<% end %>
<% end %>
<% end %>

$("#create-tag-modal").modal("hide")

#Update tags dropdown - copied this code from update_filters.js.coffee
$('#tags-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'users/tags_filter_dropdown') %>")
