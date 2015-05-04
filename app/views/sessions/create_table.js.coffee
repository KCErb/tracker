$('#households-table-div').html("<%= escape_javascript( render partial: 'table', locals: {table: @table}) %>")

$.get "/update_table"

# Handle click on member or household - generate and display modal
$ ->
  $("a.modal-link").click (e) ->
    window.ldsId = $(this).data("id")
    window.rowType = $(this).data("row-type")
    <% %w(address phone email organizations priesthood).each do |info_item| %>
    if $(this).data("<%= info_item %>")
      window.<%= info_item %> = $(this).data("<%= info_item %>")
    else
      window.<%= info_item %> = null
    <% end %>

    switch window.rowType
      when 'member'
        window.age = $(this).data("age")
        window.gender = $(this).data("gender")
        window.spokenName = $(this).data("spoken-name")
        getMemberModal(ldsId)
      when 'household'
        window.householdName = $(this).data("household-name")
        window.houseAge = $(this).data("age")
        getHouseholdModal(ldsId)
      when 'member-household'
        window.age = $(this).data("age")
        window.gender = $(this).data("gender")
        window.spokenName = $(this).data("spoken-name")
        getHouseholdModal(ldsId)
    return false

$(document).on 'click','.caret-button-right', ->
  householdId = $(this).data('id')
  $(this).removeClass("caret-button-right")
  $(this).html("<i class='fa fa-caret-down fa-lg btn'></i>")
  $(this).addClass("caret-button-down")

  $('[data-head="'+ householdId + '"][data-row-type="member"]').each ->
    $(this).addClass("caret-show")
    $(this).removeClass("caret-hide")

  return false

$(document).on 'click','.caret-button-down', ->
  householdId = $(this).data('id')
  $(this).removeClass("caret-button-down")
  $(this).html("<i class='fa fa-caret-right fa-lg btn'></i>")
  $(this).addClass("caret-button-right")

  $('[data-head="'+ householdId + '"][data-row-type="member"]').each ->
    $(this).addClass("caret-hide")
    $(this).removeClass("caret-show")


  return false

getMemberModal = (ldsId) ->
  $.get "/member_modal", lds_id: ldsId
  $.get "/member_address", lds_id: ldsId
  getMember(ldsId)

getHouseholdModal = (ldsId) ->
  $.get "/household_modal", lds_id: ldsId
  $.get "/household_address", lds_id: ldsId
  getHousehold(ldsId)

getMember = (ldsId) ->
  $.get "/members/", lds_id: ldsId, getId, 'json'

getHousehold = (ldsId) ->
  $.get "/households/", lds_id: ldsId, getId, 'json'

getId = (response) ->
  window.Id = response.id


updateKnownUnknownCounts = ->
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
