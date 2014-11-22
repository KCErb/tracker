#Custom setTimeout function to look nicer in coffee

delay = (ms, func) -> setTimeout func, ms
poll = ->
  delay 500, ->
    $.ajax
      url: "/check_status"
      success: (data) ->
        tableProgress = $('#progress-bar')
        progressMessage = $('#progress-message')
        if data.finished
          $.get '/create_table'
        else
          console.log String(data.message) + '%'
          tableProgress.css('width', String(data.progress) + '%').attr('aria-valuenow', data.progress)
          progressMessage.html(data.message)
          poll()

      dataType: "json"

poll()
