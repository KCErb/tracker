require 'nokogiri'
require 'date'
require 'json'

members_list = File.read("profile.html")
member_json =  members_list.match(/(memberProfile.individual = )({.*})/)
member_info = JSON.parse(member_json[2])
move_in_date = Date.parse(member_info["formattedMoveDate"])
address = member_info["residentialAddress"]["formattedLines"]

puts move_in_date
puts address.join("\n")

#member_info.keys.each{|key| puts key}

#File.open('html_out.html', 'w') { |file| file.write(html_out) }
