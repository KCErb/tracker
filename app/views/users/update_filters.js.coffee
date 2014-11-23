# FUNCTION DEFINITIONS
tagsHousehold = (household, tagsArr) ->
  household_has_tag = false
  tags = household.find('td.table-tags span').each ->
    tag_body = $(this).html()
    household_has_tag = true if (tagsArr.indexOf(tag_body) > -1)
  household_has_tag

tagsMembers = (members, tagsArr) ->
  any_have_tags = false
  members.each ->
    member = $(this)
    tags = member.find('td.table-tags span').each ->
      tag_body = $(this).html()
      any_have_tags = true if (tagsArr.indexOf(tag_body) > -1)
  any_have_tags

searchHousehold = (household, search_term) ->
  house_name = household.find('td a').html().toLowerCase()
  included_in_search = house_name.indexOf(search_term) > -1

searchMembers = (members, search_term) ->
  any_match_search = false
  members.each ->
    name = $(this).find('td a').html().toLowerCase()
    any_match_search = true if (name.indexOf(search_term) > -1)
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
    belongs_to_organization = true if (organizations.indexOf(filters.organization) > -1)
  belongs_to_organization

# RUNNING CODE
filters = <%= @filters %>

#go through each household and check to see if it fails any filter
visibleRowCounter = 0 #for striping table
knownCount = 0
unknownCount = 0
unreadCount = 0

$("#households-table tbody tr[data-row-type='household']").each ->
  console.log "beginning"
  household = $(this)
  householdId = household.data('id')
  members = $('[data-head="'+ householdId + '"][data-row-type="member"]')
  console.log "check0"
  household_is_known = household.hasClass("known")
  household_is_unknown = household.hasClass("unknown")
  household_name = household.find('td.household-name')
  household_has_unseen_comments = household_name.hasClass("unseen")
  console.log "check1"
  unless household_has_unseen_comments
    members.each ->
      member_name = $(this).find('td.member-name')
      household_has_unseen_comments = true if member_name.hasClass("unseen")

  passing_filters = true
  console.log "check2"
  #Now, check each filter, stopping checks once one is tripped
  if filters.tags isnt '' && passing_filters
    tagsArr = filters.tags.split(";")
    passing_filters = tagsHousehold(household, tagsArr)
    passing_filters = tagsMembers(members, tagsArr) unless passing_filters

  if filters.search isnt '' && passing_filters
    search_term = filters.search.toLowerCase()
    passing_filters = searchHousehold(household, search_term)
    passing_filters = searchMembers(members, search_term) unless passing_filters

  if filters.organization isnt '' && passing_filters
    passing_filters = organizationHousehold(household)
    passing_filters = organizationMembers(members) unless passing_filters
  console.log "check3"
  #Count up known and unknowns and unreads that have survived the filters
  if passing_filters
    knownCount += 1 if household_is_known
    unknownCount += 1 if household_is_unknown
    unreadCount += 1 if household_has_unseen_comments
  console.log "check4"
  #selecting for read only?
  if filters.unread && household_has_unseen_comments
    passing_filters = true
  else
    passing_filters = false if filters.unread
  console.log "check5"
  # passes all not-known-unknown-unread filters. Need this distinction to count
  # knowns and unknowns and unread correctly
  passesFirstFilters = passing_filters

  #known unknown are different from other filters
  if filters.unknown
    passesSecondFilters = true if household_is_unknown
  else
    passesSecondFilters = false if household_is_unknown
  console.log "check6"
  if filters.known
    passesSecondFilters = true if household_is_known
  else
    passesSecondFilters = false if household_is_known

  #show all if neither checked
  if filters.known == false && filters.unknown == false
    passesSecondFilters = true
  console.log "middle"
  #restripe table
  #remove all even odd info
  household.removeClass("even")
  household.removeClass("odd")
  members.each ->
    $(this).removeClass("even")
    $(this).removeClass("odd")

  if passesFirstFilters && passesSecondFilters
    stripeClass = if visibleRowCounter % 2 is 0 then "even" else "odd"
    unStripeClass = if visibleRowCounter % 2 is 0 then "odd" else "even"

    household.addClass("filter-show " + stripeClass)
    household.removeClass("filter-hide")

    members.each ->
      $(this).addClass("filter-show " + stripeClass)
      $(this).removeClass("filter-hide")

    visibleRowCounter += 1
  else
    household.removeClass("filter-show")
    household.addClass("filter-hide")
    members.each ->
      $(this).removeClass("filter-show")
      $(this).addClass("filter-hide")
  console.log "end"
#end each household

if visibleRowCounter == 0
  $('#empty-table').show()
else
  $('#empty-table').hide()


#Update filters UI
if filters.known
  knownString = "<i class='fa fa-check-square-o fa-lg'></i> "
else
  knownString = "<i class='fa fa-square-o fa-lg'></i> "

if filters.unknown
  unknownString = "<i class='fa fa-check-square-o fa-lg'></i> "
else
  unknownString = "<i class='fa fa-square-o fa-lg'></i> "

if filters.unread
  unreadString = "<i class='fa fa-check-square-o fa-lg'></i> "
else
  unreadString = "<i class='fa fa-square-o fa-lg'></i> "



$('#known-anchor').empty().append( knownString + String(knownCount) + " Known")
$('#unknown-anchor').empty().append( unknownString + String(unknownCount) + " Unknown")
$('#unread-anchor').empty().append( unreadString + String(unreadCount) + " Unread")

$('#tags-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'tags_filter_dropdown') %>")

$('#organization-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'organization_filter_dropdown') %>")
