$("#create-tag-modal").modal("hide")
#Update tags dropdown by rendering and then checking the correct boxes
$('#tags-filter-dropdown').replaceWith("<%= escape_javascript( render partial: 'users/tags_filter_dropdown') %>")
window.filterTable()
