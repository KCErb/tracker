#Custom setTimeout function to look nicer in coffee
window.delay = (ms, func) -> window.timer = setTimeout func, ms
poll = ->
  window.delay 500, ->
    $.ajax
      url: "/check_status"
      success: (data) ->
        tableProgress = $('#progress-bar')
        progressMessage = $('#progress-message')
        if data.finished
          $.get '/create_table'
        else
          tableProgress.css('width', String(data.progress) + '%').attr('aria-valuenow', data.progress)
          progressMessage.html(data.message)
          poll()

      dataType: "json"

poll()
