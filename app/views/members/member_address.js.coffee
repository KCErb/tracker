address = '<%= @address %>'
address_html = address.split(";").join("<br>")
$('#indiv-address').html(address_html)
