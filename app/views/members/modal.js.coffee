$("#member-info-modal").html("<%= escape_javascript(render partial: 'member_modal', locals: {member: @member}) %>")
$("#myModalLabel").html(window.spokenName + " (" + window.age + ") " + window.gender.toLowerCase())
$("#view-member").modal("show")


addMemberId = (memberId) ->
    input = document.createElement('input')
    input.type = 'hidden'
    input.name = 'comment[member_id]'
    input.value = window.memberId
    document.forms['new-comment-form'].appendChild(input);
