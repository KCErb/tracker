$("#tags-editor").replaceWith("<%= escape_javascript(render partial: 'shared/tags_editor', locals: { household: @household }) %>")
