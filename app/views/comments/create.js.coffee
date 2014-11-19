#Update timeline
<% case @moh %>
<% when Household %>
$('#timeline').replaceWith("<%= escape_javascript( render partial: 'shared/timeline', locals: {household: @moh}) %>")
moh_comments = $("tr[data-row-type='household'][data-id=<%= @moh.lds_id =%>] span[class='comment-number']")
#update household.known if not already true
<% if @moh_prev_unknown && @comment.private == false %>
household_row = $("tr[data-row-type='household'][data-id=<%= @moh.lds_id =%>]")
household_row.removeClass("unknown")
household_row.addClass("known")
#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @moh.lds_id =%>]").each ->
  $(this).removeClass("unknown")
  $(this).addClass("known")

<% end %> #end unless known already.

<% when Member %>

$('#timeline').replaceWith("<%= escape_javascript( render partial: 'shared/timeline', locals: {member: @moh}) %>")
moh_comments = $("tr[data-row-type='member'][data-id=<%= @moh.lds_id =%>] span[class='comment-number']")
#update member.household.known if not already true
<% if @moh_prev_unknown and @comment.private == false %>
#change unknown to known on household row
household_row = $("tr[data-row-type='household'][data-id=<%= @moh.household.lds_id =%>]")
household_row.removeClass("unknown")
household_row.addClass("known")
#same change on each member row
$("tr[data-row-type='member'][data-head=<%= @moh.household.lds_id =%>]").each ->
  $(this).removeClass("unknown")
  $(this).addClass("known")

<% end %> #end unless known already

<% end %> #end case statement

# note, moh will be nil/false if comment is squishable
<% if @moh %>

#Update member or household (moh) row on main page
commentCount = <%= @moh.comments.where(private: false).count %>
moh_comments.html(commentCount)


## Update table via controller call, the weakness here
# is me not knowing how to call other javascript functions. This works . . .
$.get "/update_table"

<% end %>
