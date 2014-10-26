filters = <%= @filters %>;

$("#dataTable tbody tr").each ->
    tags_string = $(this).find('td#tags').html()
    tags_string = tags_string.replace("<span class=\"label label-green\">New</span>","")
    tags_string = tags_string.replace("\n","")
    has_tags = tags_string isnt ""
    no_tags = tags_string is ""
    has_comments = $(this).find('td#comments span.comment-number').html() isnt "0"
    no_comments = $(this).find('td#comments span.comment-number').html() is "0"

    if no_tags and no_comments
      $(this).hide() unless filters.unknown
      $(this).show() if filters.unknown
    if has_tags or has_comments
      $(this).hide() unless filters.known
      $(this).show() if filters.known

$("#known-button").addClass('active') if filters.known
$("#known-button").removeClass('active') unless filters.known

$("#unknown-button").addClass('active') if filters.unknown
$("#unknown-button").removeClass('active') unless filters.unknown

# TAGS
if filters.tags isnt ''
  visibleRows = $('#dataTable tbody tr:visible');
  visibleRows.each ->
    contains_tag = false
    tags = $(this).find('td#tags span').each ->
      tag_body = $(this).html()
      contains_tag = true if filters.tags.indexOf(tag_body) > -1

    $(this).hide() unless contains_tag
    $(this).show() if contains_tag

$('#tags-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'tags_filter_dropdown') %>")

#SEARCH
if filters.search isnt ''
  visibleRows = $('#dataTable tbody tr:visible');
  visibleRows.each ->
    name = $(this).find('td a').html().toLowerCase()
    search_term = filters.search.toLowerCase()
    included_in_search = name.indexOf(search_term) > -1
    $(this).hide() unless included_in_search
    $(this).show() if included_in_search

#ORGANIZATION
if filters.organization isnt ''
  visibleRows = $('#dataTable tbody tr:visible');
  visibleRows.each ->
    belongs_to_organization = false
    organizations = $(this).data("organization")
    belongs_to_organization = true if organizations.indexOf(filters.organization) > -1
    $(this).hide() unless belongs_to_organization
    $(this).show() if belongs_to_organization

$('#organization-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'organization_filter_dropdown') %>")


#RE-STRIPE TABLE

visibleRows = $('#dataTable tbody tr:visible');

oddRows = visibleRows.filter(':odd');
evenRows = visibleRows.filter(':even');

oddRows.removeClass('even').addClass('odd');
evenRows.removeClass('odd').addClass('even');
