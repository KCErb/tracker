#Custom setTimeout function to look nicer in coffee

delay = (ms, func) -> setTimeout func, ms
poll = ->
  delay 500, ->
    $.ajax
      url: "/check_status"
      success: (data) ->
        tableProgress = $('#progress-bar')
        if data.finished
          $.get '/create_table'
        else
          console.log String(data.progress) + '%'
          tableProgress.css('width', String(data.progress) + '%').attr('aria-valuenow', data.progress)
          poll()

      dataType: "json"

poll()
