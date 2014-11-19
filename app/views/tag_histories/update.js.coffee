# Don't like this if, else, probably need to separate.
<% if @household %>

#realod tags editor and timeline
$("#tags-editor").replaceWith("<%= escape_javascript(render partial: 'shared/tags_editor', locals: { household: @household }) %>")
$('#timeline').replaceWith("<%= escape_javascript( render partial: 'shared/timeline', locals: {household: @household}) %>")

#update household tags on main page
tags = $("tr[data-row-type='household'][data-id=<%= @household.lds_id =%>] td[class='table-tags']")
<% tag_html = "" %>
<% @household.active_tags.each do |tag| %>
  <% tag_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"%>
<% end %>
tagHTML = '<%= escape_javascript tag_html.html_safe %>'
tags.html(tagHTML)

#change unknown to known on household row unless "private"
<% if @tag_history.tag.organization != current_user.lds_id && @household_prev_unknown %>

#Update rows on table for households
household_row = $("tr[data-row-type='household'][data-id=<%= @household.lds_id =%>]")
household_row.removeClass("unknown")
household_row.addClass("known")

#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @household.lds_id =%>]").each ->
  $(this).removeClass("unknown")
  $(this).addClass("known")

<% end %> #end of if private tag or known household

<% if @tag_history_deleted %>

#Update rows on table for households
household_row = $("tr[data-row-type='household'][data-id=<%= @household.lds_id =%>]")
household_row.removeClass("known")
household_row.addClass("unknown")

#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @household.lds_id =%>]").each ->
  $(this).removeClass("known")
  $(this).addClass("unknown")

<% end %> #end of if tag history just got deleted

<% else %>

#realod tags editor and timeline
$("#tags-editor").replaceWith("<%= escape_javascript(render partial: 'shared/tags_editor', locals: { member: @member }) %>")
$('#timeline').replaceWith("<%= escape_javascript( render partial: 'shared/timeline', locals: {member: @member}) %>")

#update member tags on main page
tags = $("tr[data-row-type='member'][data-id=<%= @member.lds_id =%>] td[class='table-tags']")
<% tag_html = "" %>
<% @member.active_tags.each do |tag| %>
  <% tag_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"%>
<% end %>
tagHTML = '<%= escape_javascript tag_html.html_safe %>'
tags.html(tagHTML)

#change household / members to known unless private tag
<% if @tag_history.tag.organization != current_user.lds_id && @member_prev_unknown %>

#change unknown to known on household row
household_row = $("tr[data-row-type='household'][data-id=<%= @member.household.lds_id =%>]")
household_row.removeClass("unknown")
household_row.addClass("known")

#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @member.household.lds_id =%>]").each ->
  $(this).removeClass("unknown")
  $(this).addClass("known")

<% end %> #end unless private / known

#change household / members to known unless private tag
<% if @tag_history_deleted %>

#change known to unknown on household row
household_row = $("tr[data-row-type='household'][data-id=<%= @member.household.lds_id =%>]")
household_row.removeClass("known")
household_row.addClass("unknown")

#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @member.household.lds_id =%>]").each ->
  $(this).removeClass("known")
  $(this).addClass("unknown")

<% end %> #end if history deleted

<% end %> #if else end for household / member

## Update table via controller call, again, the weakness here
# is me not knowing how to call other javascript functions. This works . . .
$.get "/update_table"
