#create modal and show
$("#shared-modal").replaceWith("<%= escape_javascript(render partial: 'shared/modal', locals: {household: @household}) %>")
#edit modal header
if window.rowType == 'member-household'
  headerString = (window.spokenName + " (" + window.age + ") " + window.gender.toLowerCase())
else
  headerString = window.householdName
$("#modal-header").html(headerString)


#edit other contact info

<% %w(phone email organizations priesthood).each do |info_item| %>
if window.<%= info_item %>?
  info = window.<%= info_item %>
  html_string = String(info)
  html_string = html_string.split(";").join("<br>")

  $('#indiv-<%= info_item %>').html(html_string)

  empty = html_string.replace(/\s/,'') == ""

  if empty then $("#info-box-<%= info_item %>").hide() else $("#info-box-<%= info_item %>").show()

else
  $("#info-box-<%= info_item %>").hide()
<% end %>


$("#private-explanation").popover();
$("#shared-modal").modal('show')

#Mark household as seen (remove unseen)
household = $("#households-table tbody tr[data-row-type='household'][data-id='<%= @household.lds_id %>'] td.unseen")
if household?
  household.removeClass('unseen')
  $.get "/update_table"
