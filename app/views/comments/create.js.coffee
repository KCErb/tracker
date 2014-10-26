#Update timeline
$('#timeline').replaceWith("<%= escape_javascript( render partial: 'members/timeline', locals: {member: @member}) %>")

#Update user row on main page
user_row = $("tr[data-id=<%= @member.lds_id =%>] span[class='comment-number']")
commentCount = parseInt(user_row.html())
commentCount += 1
user_row.html(commentCount)

#update known unknown counts
#Copy and paste from session.js.erb, I wish I knew how to just call it :(
known_count = 0
unknown_count = 0
$("#dataTable tbody tr").each ->
  tags_string = $(this).find('td#tags').html()
  tags_string = tags_string.replace("\n<span class=\"label label-green\">New</span> ","")

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
