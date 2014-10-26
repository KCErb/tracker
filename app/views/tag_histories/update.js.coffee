#Update member tags partial to reflect new tag info
$("#member-tags").replaceWith("<%= escape_javascript(render partial: 'members/member_tags', locals: { member: @member }) %>")

#Update timeline to show new tag
$('#timeline').replaceWith("<%= escape_javascript( render partial: 'members/timeline', locals: {member: @member}) %>")


#update member tags on main page
tags = $("tr[data-id=<%= @member.lds_id =%>] td[id='tags']")
<% tag_html = "" %>
<% @member.active_tags.each do |tag| %>
  <% tag_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"%>
<% end %>
tagHTML = '<%= escape_javascript tag_html.html_safe %>'
tags.html(tagHTML)

#update known unknown counts - copy and paste from
# sessions.js.coffee.erb so you'll have to keep them in sync :(
known_count = 0
unknown_count = 0
$("#dataTable tbody tr").each ->
  tags_string = $(this).find('td#tags').html()
  tags_string = tags_string.replace("<span class=\"label label-green\">New</span>","")

  has_tags = tags_string isnt ""
  no_tags = tags_string is ""
  has_comments = $(this).find('td#comments span.comment-number').html() isnt "0"
  no_comments = $(this).find('td#comments span.comment-number').html() is "0"

  unknown_count += 1 if no_tags and no_comments
  known_count += 1 if has_tags or has_comments

$('#known-anchor').empty().append( String(known_count) + " Known")
$('#unknown-anchor').empty().append( String(unknown_count) + " Unknown")


## Update table via controller call, again, the weakness here
# is me not knowing how to call other javascript functions. This works . . .
$.get "/update_table"
