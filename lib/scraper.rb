class Scraper
  TESTING = false

  attr_reader :member_list, :user, :member_info, :cookies

  def initialize(params_or_cookies)
    if !TESTING
      if params_or_cookies.is_a? Hash
        init_agent_with_params(params_or_cookies)
      else
        init_agent_from_cookies(params_or_cookies)
      end
    end
  end

  def init_agent_with_params(params)
    @agent = Mechanize.new
    page = @agent.get 'https://signin.lds.org/SSOSignIn/'
    page.forms.each do |f|
      if f.action == '/login.html'
        @login_form = f
      end
    end
    @login_form.field_with( name: 'username').value = params[:username]
    @login_form.field_with( name: 'password').value = params[:password]
    @agent.submit(@login_form)
    stringio = StringIO.new
    @agent.cookie_jar.save(stringio, session: true)
    @cookies = stringio.string
  end

  def init_agent_from_cookies(cookies)
    @agent = Mechanize.new
    @agent.cookie_jar.load StringIO.new(cookies)
  end

  def get_member_list
    if TESTING
      @path = File.dirname(__FILE__)
      @member_list = File.read(@path + "/member-list.html")
    else
      web_address = "https://www.lds.org/mls/mbr/records/member-list?lang=eng"
      @member_list = @agent.get(web_address).body
    end
  end

  def user
    #only called on auth, so I reset filters
    m = @member_list.match(/(prop42 = )(.*?);/)
    lds_id = m[2]
    user = User.find_by_lds_id(lds_id.to_s)
    if user
      @user = user
    else
      create_user
    end
    @user.filters[:known] = true
    @user.filters[:unknown] = true
    @user.filters[:tags] = ""
    @user.filters[:search] = ""
    @user.filters[:organization] = ""
    @user.save
    @user
  end

  def in_ward?
    ward = @member_list.match(/(prop2 = )(.*?);/)
    ward == '2968:First Ward'
  end

  def create_user
    m = @member_list.match(/(prop42 = )(.*?);/)
    lds_id = m[2]
    m = @member_list.match(/(prop41 = ")(.*?)"/)
    calling = m[2]
    doc = Nokogiri::HTML(@member_list)
    data = {}
    data_xpath = %Q(//td/a[@href="/mls/mbr/records/member-profile/#{lds_id}?lang=eng"])
    doc.xpath(data_xpath).each do |row|
      row.attributes.each do |attr|
        data[attr[1].name.gsub(/data-/,'')] = attr[1].value
      end
    end

    name =  data["spoken-name"]
    @user = User.new(lds_id: lds_id, calling: calling, name: name)
    @user.filters = { known: false,
                      unknown: false,
                      tags: "",
                      search: ""
                    }
    @user.save
    @user
  end

  def create_member(lds_id)
    member  = Member.new(lds_id: lds_id)

    organizations = %w(EldersQuorum HighPriestsGroup ReliefSociety SingleAdult
    YoungSingleAdult YoungMen YoungWomen Primary)

    addresses = {}
    # Get organization links
    @page.xpath("//select[@id='organization']").children.each do |option|
      organization_name = option.children.to_s.gsub(/[[:space:]]/,'')
      id = option.attributes["value"].value
      addresses[organization_name] = id if organizations.include? organization_name
    end

    #fetch organization lists from lds.org if you don't already have them.
    unless @organization_mapping
      @organization_mapping = {}
      organizations.map{|organization_name| @organization_mapping[organization_name] = []}

      organizations.each do |organization_name|
        if TESTING
          html = File.read(@path + "/#{organization_name}.html")
        else
          address = "https://www.lds.org/mls/mbr/records/member-list?lang=eng&organization=#{addresses[organization_name]}"
          html = @agent.get(address).body
        end

        doc = Nokogiri::HTML(html)
        doc.xpath("//table[@id='dataTable']/tbody/tr").each do |person|
          @organization_mapping[organization_name] << person['data-id']
        end
      end
    end

    #add organizations to new member
    organizations.each do |organization_name|
      if @organization_mapping[organization_name].include? lds_id
        member.organizations << group_to_tag(organization_name)
      end
    end

    member.save
    member
  end #end of create_member

  def create_base_tags
    Tag.create( body:"Active", organization: "All", color: "blue")
    Tag.create( body:"Do Not Contact", organization: "All", color: "red")
    Tag.create( body:"Moved", organization: "All", color: "red")
    Tag.create( body:"Part Member", organization: "All", color: "gold")
    Tag.create( body:"New", organization: "Internal", color: "green")
  end

  def group_to_tag(string)
    string.gsub(/(?<=[A-Za-z])(?=[A-Z])/, ' ')
  end

  def create_page

    get_member_list unless @member_list
    #create page only called on refresh. So refreshing will kill all filters
    # since I'm calling user here
    user
    @page = Nokogiri::HTML(@member_list)

    @page.xpath("//*[contains(concat(' ', @class, ' '), ' member-card ')]").each do |elem|
      elem['href'] = "#" # "/member_timeline"
      elem['data-remote'] = "true"
      elem['data-type'] = "json"
    end
    #remove this stuff, it's already in the popover
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' sex ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' email ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' age ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' phone ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' birthdate ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' hidden ')]").remove
    @page.xpath("//*[contains(concat(' ', @class, ' '), ' hidden-phone ')]").remove
    @page.xpath("//input[@type='checkbox']").remove

    # insert comments and tags
    @page.xpath("//table[@id='dataTable']/thead/tr").each do |row|
      row << "<th id='tags' class='tags'>Tags</th>"
      row << "<th id='comments' class='comments'>Comments</th>"
    end

    tags = Tag.all
    create_base_tags if tags.length == 0
    #EACH ROW
    @page.xpath("//table[@id='dataTable']/tbody/tr").each_with_index do |row, index|
      lds_id = row['data-id']
      member = Member.find_by_lds_id(lds_id)
      member = create_member(lds_id) unless member

      row['class'] = index.even? ? "even" : "odd"

      #ORGANIZATION
      row['data-organization'] = member.organizations.join(";")

      #TAGS
      tags_html = "<td id='tags'>"
      member.tags.each do |tag|
        tags_html += "<span class='label label-#{tag.color}' >#{tag.body}</span> "
      end

      tags_html += "</td>"
      row << tags_html

      #COMMENTS
      row << "<td id='comments'><i class='fa fa-comment fa-lg'></i> <span class='comment-number'>#{member.comments.count}</span></td>"
    end

    #retreive table
    @table = @page.xpath("//table[@id='dataTable']").to_html
  end

  def handle_auth
    get_member_list unless @member_list
    case
    when @member_list.include?("<title>Member List</title>") && @member_list.include?("s.prop2 = '2968:First Ward';")
      :authorized
    when @member_list.include?("<title>Member List</title>")
      :wrong_ward
    when @member_list.include?("<title>Access Denied</title>")
      :not_authorized
    when @member_list.include?("<title>Sign in</title>")
      :bad_credentials
    end
  end

  def get_member_info(lds_id)
    @member_info = {}
    if TESTING
      @path = File.dirname(__FILE__)
      file = File.read(@path + "/householdProfile.json")
      json = JSON.parse(file)
    else
      response = @agent.get "https://www.lds.org/directory/services/ludrs/mem/householdProfile/#{lds_id}"
      json = JSON.parse(response.body)
    end

    household = json["householdInfo"]
    #Get Address
    address_data = household["address"]
    address_arr = []
    (1..5).each do |num|
      addr_row = address_data["addr#{num}"]
      address_arr << addr_row unless addr_row == ""
    end
    address = address_arr.join("\n")
    @member_info["address"] = address unless address == ""

    #get house email and phone
    house_phone = household["phone"]
    house_email = household["email"]


    #go through head, spouse, others and find member
    head = json["headOfHousehold"]
    spouse = json["spouse"]
    other_household_members = json["otherHouseholdMembers"]
    member = "" #member is set in block, so define out here


    if head["individualId"].to_s == lds_id
      role = "head"
      member = head
    end

    has_spouse = spouse != nil

    if has_spouse
      if spouse["individualId"].to_s == lds_id
        role = "spouse"
        member = spouse
      end
    end

    unless role
      other_household_members.each do |mem|
        next unless mem["individualId"].to_s == lds_id
        role = "other"
        member = mem
      end
    end

    # get phone and email
    indiv_phone = member["phone"]
    indiv_email = member["email"]

    #now create list of other members
    other_members_list = []
    case
    when (role == "head" && has_spouse)
      other_members_list << spouse["name"]# + " (spouse)"
      other_household_members.each{|mem| other_members_list << mem["name"]}
    when role == "head"
      other_household_members.each{|mem| other_members_list << mem["name"]}
    when role == "spouse"
      other_members_list << head["name"]# + " (spouse)"
      other_household_members.each{|mem| other_members_list << mem["name"]}
    when role == "other"
      other_members_list << head["name"]
      other_members_list << spouse["name"]
      other_household_members.each do |mem|
        other_members_list << mem["name"] unless mem["individualId"].to_s == lds_id
      end
    end

    @member_info["household_names"] = other_members_list.join("\n")

    #compare household and member contact info and choose which to use
    @member_info["phone"] = case
    when indiv_phone != ""
      indiv_phone
    when house_phone != ""
      house_phone
    end

    @member_info["email"] = case
    when indiv_email != ""
      indiv_email
    when house_email != ""
      house_email
    end
  end

end
