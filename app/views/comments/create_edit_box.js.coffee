<% if @moh.is_a? Household %>
$('#timeline-comment-<%= @comment.id %>').replaceWith("<%= escape_javascript( render partial: 'comments/edit_box', locals: {comment: @comment, household: @moh}) %>")
<% else %>
$('#timeline-comment-<%= @comment.id %>').replaceWith("<%= escape_javascript( render partial: 'comments/edit_box', locals: {comment: @comment, member: @moh}) %>")
<% end %>
