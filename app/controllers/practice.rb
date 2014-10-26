require 'nokogiri'
require 'date'
require 'json'

tagged_groups = %w(EldersQuorum HighPriestsGroup ReliefSociety SingleAdult
                   YoungSingleAdult YoungMen YoungWomen Primary)

h = {}
groups = {}
tagged_groups.map{|group_name| groups[group_name] = []}

members_list = File.read("member-list.html")

page = Nokogiri::HTML(members_list)
# Get organization links
page.xpath("//select[@id='organization']").children.each do |option|
  group_name = option.children.to_s.gsub(/[[:space:]]/,'')
  id = option.attributes["value"].value
  h[group_name] = id if tagged_groups.include? group_name
end

tagged_groups.each do |group_name|
  #address = "https://www.lds.org/mls/mbr/records/member-list?lang=eng&organization=#{h[group_name]}"
  #html = agent.get(address).body
  html = File.read("#{group_name}.html")
  doc = Nokogiri::HTML(html)
  doc.xpath("//table[@id='dataTable']/tbody/tr").each do |person|
    groups[group_name] << person['data-id']
  end
end


metas = page.xpath("//meta")
scripts = page.xpath("//script")
links = page.xpath("//link")
searchbar = page.xpath("//input[@id='find-individual']")

#prep table
#Make emails searchable but hide them
page.xpath("//*[contains(concat(' ', @class, ' '), ' email ')]").each do |elem|
  elem['class'] = elem['class'] << ' hidden'
end
#remove this stuff, it's already in the popover
page.xpath("//*[contains(concat(' ', @class, ' '), ' sex ')]").remove
page.xpath("//*[contains(concat(' ', @class, ' '), ' age ')]").remove
page.xpath("//*[contains(concat(' ', @class, ' '), ' phone ')]").remove
page.xpath("//*[contains(concat(' ', @class, ' '), ' birthdate ')]").remove
page.xpath("//input[@type='checkbox']").remove

# insert comments and tags
page.xpath("//table[@id='dataTable']/thead/tr").each do |row|
  row << "<th id='tags' class='tags'>Tags</th>"
  row << "<th id='comments' class='comments'>Comments</th>"
end

page.xpath("//table[@id='dataTable']/tbody/tr").each_with_index do |row, i|
  lds_id = row['data-id']
  tags = []
  tagged_groups.each{|group| tags << group if groups[group].include? lds_id}
  row << "<td id='tags'>#{i}</td>"
  row << "<td id='comments'>#{i}</td>"
end

#retreive table
table = page.xpath("//table[@id='dataTable']")

html_out = %(<!DOCTYPE html>
<html lang="en">
<head>
<title>Tracker</title>
)

[metas, links].each do |elem|
  html_out += elem.to_html
end

html_out +=%(</head>
<body class="pf-responsive lang-eng  " >
<div class="container">
  <h2 class="pageTitle">
    <span id="pageTitleText">Tracker</span>
  </h2>
)

[searchbar, table].each do |elem|
  html_out += elem.to_html
end


html_out +=%(</div>
</body>)

html_out += scripts.to_html + "</html>"


File.open('html_out.html', 'w') { |file| file.write(html_out) }
