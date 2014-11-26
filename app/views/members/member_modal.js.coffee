#create modal and show
$("#shared-modal").replaceWith("<%= escape_javascript(render partial: 'shared/modal', locals: {member: @member}) %>")
#edit modal header
if window.age?
  headerString = window.spokenName + " (" + window.age + ") " + window.gender.toLowerCase()
else
  headerString = window.spokenName

$("#modal-header").html(headerString)

#edit other contact info
<% %w(phone email organizations priesthood).each do |info_item| %>
if window.<%= info_item %>
  info = window.<%= info_item %>
  html_string = String(info)
  html_string = html_string.split(";").join("<br>")
  $('#indiv-<%= info_item %>').html(html_string)
  empty = html_string.replace(/\s/,'') == ""
  infoItem = $("#info-box-<%= info_item %>")
  if empty then infoItem.hide() else infoItem.show()
else
  $("#info-box-<%= info_item %>").hide()
<% end %>

$("#private-explanation").popover();
$("#shared-modal").modal('show')

#Mark member as seen (remove unseen)
member = $("#households-table tbody tr[data-row-type='member'][data-id='<%= @member.lds_id %>'] td.unseen")
if member?
  member.removeClass('unseen')
  $.get "/update_table"
