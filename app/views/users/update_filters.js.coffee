# UPDATE FILTERS
window.updateFilters = (source, value, id) ->
  #callback to updateTable on shown modal
  filters = JSON.parse($('#filters').html())
  filters.update_category = source
  filters.update_value = value
  filters.update_id = id

  switch source
    when 'known'
      if filters.known then filters.known = false else filters.known = true
    when 'unknown'
      if filters.unknown then filters.unknown = false else filters.unknown = true
    when 'unread'
      if filters.unread then filters.unread = false else filters.unread = true
    when 'tags'
      index = filters.tags.indexOf(value);
      if index > -1
        filters.tags.splice(index,1)
      else
        filters.tags.push(value)
    when 'organization'
      if filters.organization == value
        filters.organization = ''
      else
        filters.organization = value
    when 'search'
      searchText = $('#search-filter').val()
      filters.search = searchText

  #hold off on search support for the moment
  filtersString = JSON.stringify(filters);
  $('#filters').html(filtersString)
  #Update dropdowns right now!
  filters = JSON.parse($('#filters').html())
  switch filters.update_category
    when 'tags'
      updateTags(filters)
    when 'organization'
      updateOrganizations(filters)
  window.filterTable()

window.delaySearch = ->
  clearTimeout window.timer if window.timer?
  window.delay 500, ->
    window.updateFilters('search', '', null)

# FUNCTION DEFINITIONS
tagsHousehold = (household, tagsArr) ->
  household_has_tag = false
  for tag_body in tagsArr
    household_has_tag = true if (household.html().search(tag_body) > -1)
  household_has_tag

tagsMembers = (members, tagsArr) ->
  any_have_tags = false
  members.each ->
    for tag_body in tagsArr
      any_have_tags = true if ($(this).html().search(tag_body) > -1)
      break
  any_have_tags

searchHousehold = (household, search_term) ->
  (household.html().toLowerCase().search(search_term) > -1)

searchMembers = (members, search_term) ->
  any_match_search = false
  members.each ->
    any_match_search = true if ($(this).html().toLowerCase().search(search_term) > -1)
  any_match_search

organizationHousehold = (household) ->
  organizations = household.data('organization')
  if organizations
    organizations.indexOf(filters.organization) > -1
  else
    false

organizationMembers = (members) ->
  belongs_to_organization = false
  members.each ->
    organizations = $(this).data("organization")
    if organizations
      belongs_to_organization = true if (organizations.indexOf(filters.organization) > -1)

  belongs_to_organization

updateTags = (filters) ->
  idString = "#tag-" + String(filters.update_id) + '-filter-li'
  tagLI = $(idString)

  if (filters.tags.indexOf(filters.update_value) > -1)
    checkString = "<i class='fa fa-check-square-o fa-2x'></i>"
    tagLI.addClass('active')
  else
    checkString = "<i class='fa fa-square-o fa-2x'></i>"
    tagLI.removeClass('active')

  idString = "#tag-" + String(filters.update_id) + '-filter'
  $(idString).html(checkString)

updateOrganizations = (filters) ->
  for i in [1..8] by 1
    idString = "#organization-" + String(i) + '-filter-li'
    organizationLI = $(idString)

    if filters.update_id == i
      checkString = toggleOrganization(filters, organizationLI)
    else
      checkString = "<i class='fa fa-square-o fa-2x'></i>"
      organizationLI.removeClass('active')

    idString = "#organization-" + String(i) + '-filter'
    $(idString).html(checkString)

toggleOrganization = (filters, organizationLI) ->
  if filters.organization == filters.update_value
    checkString = "<i class='fa fa-check-square-o fa-2x'></i>"
    organizationLI.addClass('active')
  else
    checkString = "<i class='fa fa-square-o fa-2x'></i>"
    organizationLI.removeClass('active')
  checkString

filterHousehold = (household) ->
  #12ms
  householdId = household.data('id')
  # 40ms
  memberCount = parseInt(household.data('member-count'))
  if memberCount > 1
    members = $('#' + householdId + '-0')
    for i in [1..memberCount - 1] by 1
      members = members.add('#' + householdId + '-' + String(i) )
  else
    members = null
  # about 50ms
  household_is_known = household.hasClass("known")
  household_is_unknown = household.hasClass("unknown")
  household_name = household.find('.household-name')
  household_has_unseen_comments = household_name.hasClass("unseen")

  unless household_has_unseen_comments || !members? #no members?
    members.each ->
      member_name = $(this).find('.member-name')
      household_has_unseen_comments = true if member_name.hasClass("unseen")

  passing_filters = true
  #tags and search filtering ~100ms
  #Now, check each filter, stopping checks once one is tripped
  if filters.tags.length isnt 0 && passing_filters
    tagsArr = filters.tags
    passing_filters = tagsHousehold(household, tagsArr)
    if members?
      passing_filters = tagsMembers(members, tagsArr) unless passing_filters

  if filters.search isnt '' && passing_filters
    search_term = filters.search.toLowerCase()
    passing_filters = searchHousehold(household, search_term)
    if members?
      passing_filters = searchMembers(members, search_term) unless passing_filters

  if filters.organization isnt '' && passing_filters
    passing_filters = organizationHousehold(household)
    if members?
      passing_filters = organizationMembers(members) unless passing_filters

  #~2ms
  #Count up known and unknowns and unreads that have survived the filters
  if passing_filters
    window.knownCount += 1 if household_is_known
    window.unknownCount += 1 if household_is_unknown
    window.unreadCount += 1 if household_has_unseen_comments

  #selecting for read only?
  if filters.unread && household_has_unseen_comments
    passing_filters = true
  else
    passing_filters = false if filters.unread

  # passes all not-known-unknown-unread filters. Need this distinction to count
  # knowns and unknowns and unread correctly
  passesFirstFilters = passing_filters

  #known unknown are different from other filters
  if filters.unknown
    passesSecondFilters = true if household_is_unknown
  else
    passesSecondFilters = false if household_is_unknown

  if filters.known
    passesSecondFilters = true if household_is_known
  else
    passesSecondFilters = false if household_is_known

  #show all if neither checked
  if filters.known == false && filters.unknown == false
    passesSecondFilters = true

  #restripe table ~120ms
  #remove all even odd info
  household.removeClass("even odd")
  if members?
    members.each ->
      $(this).removeClass("even odd")

  if passesFirstFilters && passesSecondFilters
    stripeClass = if window.visibleRowCounter % 2 is 0 then "even" else "odd"
    unStripeClass = if window.visibleRowCounter % 2 is 0 then "odd" else "even"

    household.addClass("filter-show " + stripeClass)
    household.removeClass("filter-hide")
    if members?
      members.each ->
        $(this).addClass("filter-show " + stripeClass)
        $(this).removeClass("filter-hide")

    window.visibleRowCounter += 1
  else
    household.removeClass("filter-show")
    household.addClass("filter-hide")
    if members?
      members.each ->
        $(this).removeClass("filter-show")
        $(this).addClass("filter-hide")

window.filterTable = ->
  #get filters
  window.filters = JSON.parse($('#filters').html())

  #go through each household and check to see if it fails any filter
  window.visibleRowCounter = 0 #for striping table
  window.knownCount = 0
  window.unknownCount = 0
  window.unreadCount = 0

  window.time_cost = 0.0

  households = $("#households-table tr[data-row-type='household']")

  households.each ->
    household = $(this)
    filterHousehold(household)

  if window.visibleRowCounter == 0
    $('#empty-table').show()
  else
    $('#empty-table').hide()

  #Update filters UI
  if filters.known
    knownString = "<i class='fa fa-check-square-o fa-lg'></i> "
    $('#known-filter-li').addClass('active')
  else
    knownString = "<i class='fa fa-square-o fa-lg'></i> "
    $('#known-filter-li').removeClass('active')

  if filters.unknown
    unknownString = "<i class='fa fa-check-square-o fa-lg'></i> "
    $('#unknown-filter-li').addClass('active')
  else
    unknownString = "<i class='fa fa-square-o fa-lg'></i> "
    $('#unknown-filter-li').removeClass('active')

  if filters.unread
    unreadString = "<i class='fa fa-check-square-o fa-lg'></i> "
    $('#unread-filter-li').addClass('active')
  else
    unreadString = "<i class='fa fa-square-o fa-lg'></i> "
    $('#unread-filter-li').removeClass('active')

  $('#known-filter').html(knownString + String(window.knownCount) + " Known")
  $('#unknown-filter').html(unknownString + String(window.unknownCount) + " Unknown")
  $('#unread-filter').html(unreadString + String(window.unreadCount) + " Unread")
#END FUNCTIONS

#call filter table when this script is run for the first time to put counts in navbar
window.filterTable()


$('#tags-filter-dropdown').click (e) ->
  e.stopPropagation()

$('#organization-filter-dropdown').click (e) ->
  e.stopPropagation()
