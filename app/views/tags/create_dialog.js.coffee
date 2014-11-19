$("#create-tag-modal").replaceWith("<%= escape_javascript(render partial: 'create_modal', locals: {tag: @tag}) %>")
$("#create-tag-modal").modal("show")
