class Scraper
  if Rails.env.production?
    TESTING = false
  else
    TESTING = true
  end

  attr_reader :member_list, :user, :member_info, :cookies

  def initialize(params_or_cookies)
    @path = File.dirname(__FILE__)
    if params_or_cookies.is_a? Hash
      init_agent_with_params(params_or_cookies)
    else
      init_agent_from_cookies(params_or_cookies)
    end unless TESTING
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
      @member_list = File.read(@path + "/member-list.html")
    else
      web_address = "https://www.lds.org/mls/mbr/records/member-list?lang=eng"
      @member_list = @agent.get(web_address).body
    end
  end

  def get_households
    if TESTING
      @households = File.read(@path + "/households.json")
    else
      web_address = "https://www.lds.org/directory/services/ludrs/photo/household-members/2968/"
      @households = @agent.get(web_address).body
    end
    @households = JSON.parse(@households)
  end

  def user
    m = @member_list.match(/(prop42 = )(.*?);/)
    lds_id = m[2].to_s
    user = User.find_by_lds_id(lds_id)
    if user
      @user = user
    else
      create_user(lds_id)
    end
    @user.filters[:known] = false
    @user.filters[:unknown] = false
    @user.filters[:unread] = false
    @user.filters[:tags] = ""
    @user.filters[:search] = ""
    @user.filters[:organization] = ""
    @user.save
    @user
  end

  def create_user(lds_id)
    #fetch calling
    m = @member_list.match(/(prop41 = ")(.*?)"/)
    calling = m[2]

    #fetch spoken name
    if TESTING
      html = File.read(@path + "/householdProfile.json")
    else
      root = "https://www.lds.org/directory/services/ludrs/mem/householdProfile/"
      html = @agent.get(root + "#{lds_id}").body
    end
    household_profile = JSON.parse(html)
    #determine if user is head
    case
    when household_profile['headOfHousehold']['individualId'].to_s == lds_id
      name = household_profile['headOfHousehold']['name']
    when household_profile['spouse']['individualId'].to_s == lds_id
      name = household_profile['spouse']['name']
    end
    spoken_name = name.split(',').reverse.join(' ').strip
    #fetch organization
    organization = get_organization(lds_id)
    #create user
    @user = User.new(lds_id: lds_id, calling: calling, name: spoken_name, organization: organization)
    @user.filters = { known: true,
      unknown: true,
      tags: "",
      search: ""
    }
    @user.save
    @user
  end

  def get_organization(lds_id)
    if TESTING
      wlp = File.read(@path + "/ward-leadership-positions.json")
    else
      wlp_add = "https://www.lds.org/directory/services/ludrs/1.1/unit/ward-leadership-positions/2968/true"
      wlp = @agent.get(wlp_add).body
    end

    leader_groups = JSON.parse(wlp)['wardLeadership'] #returns array of groupKey and groupNames
    organization = "unknown"
    leader_groups.each do |group|
      group_name = group["groupName"]
      key = group["groupKey"]
      if TESTING
        group_list = File.read(@path + "/leaders-1179.json")
      else
        group_add =   "https://www.lds.org/directory/services/ludrs/1.1/unit/stake-leadership-group-detail/2968/#{key}/1"
        group_list = @agent.get(group_add).body
      end
      leaders_ids = JSON.parse(group_list)['leaders'].map{|leader| leader['individualId'].to_s}
      if leaders_ids.include? lds_id
        organization = group_name
        break
      end
    end

    organization
  end

  def create_member(lds_id)
    member  = Member.new(lds_id: lds_id)

    # find household and add member to it if household exists, if that household hasn't been
    # created yet (expected scenario) then do nothing, the member will be added on
    # household creation.
    household = @households.select do |household|
      household["familyMembers"].to_s.include? lds_id
    end
    unless household.empty? #shouldn't ever happen
      head_id = household[0]["headOfHouseholdId"].to_s
      household = Household.find_by_lds_id(head_id)
      if household
        household.members << member
        household.save
      end
    end

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
      member.organizations << group_to_tag(organization_name) if @organization_mapping[organization_name].include? lds_id
    end

    if TESTING
      html = File.read(@path + "/profile.html")
    else
      html = @agent.get("https://www.lds.org/mls/mbr/records/member-profile/#{lds_id}?lang=eng").body
    end
    cant_import =  html.include?("birthPlace\":null")
    member_json =  html.match(/(memberProfile.individual = )({.*})/)

    member_info = JSON.parse(member_json[2])

    #moved in
    #if cant import don't bother trying
    if cant_import
      member.moved_in = Time.zone.now
      member.move_type = "tracker"
    else
    # if can import then let's try
      if member_info["formattedMoveDate"]
        move_in_date = Date.parse(member_info["formattedMoveDate"])
        member.moved_in = move_in_date
        member.move_type = "moved-in"
      end
      # if that failed, then they may have been born into the ward
      if member_info["formattedMoveDate"] == nil && member_info["formattedBirthDate"]
        birth_date = Date.parse(member_info["formattedBirthDate"])
        member.moved_in = birth_date
        member.move_type = "born"
      end
      # at this point, we know that we can import but it's failing
      # so we'll just set it to unknown
      if member.moved_in == nil
        member.moved_in = Time.now - 60*60*24*365.25*5
        member.move_type = "unknown"
      end
    end

    member.save

    #add new tag if new
    if Date.today - member.moved_in < 90
      new_tag = Tag.find_by_body("New")
      tag_history = TagHistory.new( tag_id: new_tag.id, member_id: member.id)
      tag_history.added_by << "Tracker"
      tag_history.added_at << Time.zone.now
      tag_history.save
    end
    #return member
    member
  end #end of create_member

  def create_non_member(spouse_id)
    # a to avoid someone moving in and having the id I created d'oh
    new_id = rand.to_s[2..10] + 'NM'
    while Member.find_by_lds_id(new_id)
      new_id = rand.to_s[2..10] + 'NM'
    end
    non_member  = Member.new(lds_id: new_id) #I guess I could rename member to person but what a hassle!
    spouse = Member.find_by_lds_id(spouse_id.to_s)

    if spouse.moved_in
      non_member.moved_in = spouse.moved_in
      non_member.move_type = 'moved-in'
      non_member.save

      #add new tag if new
      if Date.today - non_member.moved_in < 90
        new_tag = Tag.find_by_body("New")
        tag_history = TagHistory.new( tag_id: new_tag.id, member_id: non_member.id)
        tag_history.added_by << "Tracker"
        tag_history.added_at << Time.zone.now
        tag_history.save
      end

      #Add non non_member tag
      new_tag = Tag.find_by_body("Non Member")
      tag_history = TagHistory.new( tag_id: new_tag.id, member_id: non_member.id)
      tag_history.added_by << "Tracker"
      tag_history.added_at << Time.zone.now
      tag_history.save

      #return non_member
      non_member
    else
      #return nothing
      nil
    end
  end #end of create_non_member


  def create_household(lds_id, household_members)
    household  = Household.new(lds_id: lds_id)

    #fetch profile
    if TESTING
      html = File.read(@path + "/householdProfile.json")
    else
      root = "https://www.lds.org/directory/services/ludrs/mem/householdProfile/"
      html = @agent.get(root + "#{lds_id}").body
    end

    household_profile = JSON.parse(html)

    #determine if spouse is non member
    if household_profile['spouse']
      part_member = household_profile['spouse']['individualId'] == -1
      relation = 'spouse' if part_member
      spouse = 'headOfHousehold' if part_member
    end


    #determine if head is non member
    unless part_member
      part_member = household_profile['headOfHousehold']['individualId'] == -1
      relation = 'headOfHousehold'
      spouse = 'spouse'
    end

    if part_member
      non_member = create_non_member(household_profile[spouse]['individualId'])
    end

    #add non members in correct order - this is messy :(
    household_members["familyMembers"].each_with_index do |family_member, index|
      if index == 0 && part_member
        household.members << non_member if relation == 'headOfHousehold'
      end
      if index == 1 && part_member
        household.members << non_member if relation == 'spouse'
      end

      member_lds_id = family_member["individualId"].to_s
      member = Member.find_by_lds_id(member_lds_id)
      if member
        household.members << member
      end
    end

    ## Edge case! add non member wife to house with only 1 man
    if household_members["familyMembers"].length == 1 && part_member
      household.members << non_member if relation == 'spouse'
    end

    #fetch mls profile to get move-in info
    if TESTING
      html = File.read(@path + "/profile.html")
    else
      html = @agent.get("https://www.lds.org/mls/mbr/records/member-profile/#{lds_id}?lang=eng").body
    end

    cant_import =  html.include?("birthPlace\":null")
    can_import = !cant_import
    member_json =  html.match(/(memberProfile.individual = )({.*})/)

    member_info = JSON.parse(member_json[2])

    if cant_import
      household.moved_in = Time.zone.now
      household.move_type = "tracker"
    else
      if member_info["formattedMoveDate"]
        move_in_date = Date.parse(member_info["formattedMoveDate"])
        household.moved_in = move_in_date
        #household move_type is always moved-in, but it makes the partials
        #simpler if households and members have the same type of info
        household.move_type = "moved-in"
      end

      if member_info["formattedMoveDate"] == nil && member_info["formattedBirthDate"] && can_import
        birth_date = Date.parse(member_info["formattedBirthDate"])
        household.moved_in = birth_date
        household.move_type = "born"
      end

      #At this point, the user can import, but there's just no info available
      # set to unknown - this may not ever get used
      if household.moved_in == nil
        #moved_in still needs to be a date time for the new member filters, so
        #we'll arbitraily set it for 5 years ago
        household.moved_in = Time.zone.now - 60*60*24*365.25*5
        household.move_type = "unknown"
      end
    end

    household.save

    #add new tag if new
    if Date.today - household.moved_in < 90
      new_tag = Tag.find_by_body("New")
      tag_history = TagHistory.new( tag_id: new_tag.id, household_id: household.id)
      tag_history.added_by << "Tracker"
      tag_history.added_at << Time.zone.now
      tag_history.save
    end

    #add part member tag if needed
    if part_member
      new_tag = Tag.find_by_body("Part Member")
      tag_history = TagHistory.new( tag_id: new_tag.id, household_id: household.id)
      tag_history.added_by << "Tracker"
      tag_history.added_at << Time.zone.now
      tag_history.save
    end
    #return household
    household
  end #end of create_household

  def create_base_tags
    Tag.create( body:"Active", organization: "All", color: "blue")
    Tag.create( body:"New", organization: "Internal", color: "green")
    Tag.create( body:"Follow Up", organization: "All", color: "green")

    Tag.create( body:"Less Active", organization: "All", color: "gold")
    Tag.create( body:"Part Member", organization: "Internal", color: "gold")

    Tag.create( body:"Do Not Contact", organization: "All", color: "red")
    Tag.create( body:"Moved", organization: "All", color: "red")
    Tag.create( body:"Non Member", organization: "Internal", color: "red")
  end

  def group_to_tag(string)
    string.gsub(/(?<=[A-Za-z])(?=[A-Z])/, ' ')
  end

  def create_table
    get_member_list unless @member_list
    get_households
    user

    # update those who were imported by the tracker if applicable
    if can_fix?
      needs_fixin = Member.where(move_type: "tracker").all
      needs_fixin += Household.where(move_type: "tracker").all
      if needs_fixin.length > 0
        @user.progress_message = 'Updating Member Info'
        @user.save
        fix_that_which needs_fixin
      end
    end
    @user.progress_message = 'Parsing Data'
    @user.save
    @table = %Q(
    <table id='households-table' class='table'>
    <thead>
    <th></th>
    <th>NAME</th>
    <th>TAGS</th>
    <th>COMMENTS</th>
    </thead>
    <tbody>
    )

    @page = Nokogiri::HTML(@member_list)

    table_rows = @page.xpath("//table[@id='dataTable']/tbody/tr")

    #TAGS
    tags = Tag.all
    create_base_tags if tags.length == 0

    #empty hashes for loading
    @individuals_anchors = {}
    @members_html = {}

    table_rows.each_with_index do |row, index|
      gender = row.xpath("./*[contains(concat(' ', @class, ' '), ' sex ')]").inner_html
      gender = gender.downcase.include?("f") ? "female" : "male"
      email = row.xpath("./*[contains(concat(' ', @class, ' '), ' email ')]/a/span").inner_html.sub(/<i.*<\/i>/,'')
      phone  = row.xpath("./*[contains(concat(' ', @class, ' '), ' phone ')]/a").inner_html
      age  = row.xpath("./*[contains(concat(' ', @class, ' '), ' age ')]").inner_html

      anchor = row.xpath("./td/a")[0]
      spoken_name = anchor.children[0].text.strip.split(',').reverse.join(' ').strip
      anchor['href'] = "#"
      anchor['class'] = 'modal-link'
      anchor['data-row-type'] = 'member'
      anchor['data-remote'] = "true"
      anchor['data-type'] = "json"
      anchor['data-spoken-name'] = spoken_name
      anchor['data-gender'] = gender
      anchor['data-phone'] = phone
      anchor['data-email'] = email
      anchor['data-age'] = age
      anchor['data-organizations'] = 'needs_organizations'
      anchor.inner_html = "%%" + spoken_name + " (#{age})" + "%%"
      lds_id = anchor['data-id']
      @individuals_anchors[lds_id] = anchor.to_html
    end


    #Individaul members
=begin
    @page.xpath("//table[@id='dataTable']/tbody/tr/td/a").each_with_index do |anchor|
      anchor['href'] = "#"
      anchor['class'] = 'modal-link'
      anchor['data-row-type'] = 'member'
      anchor['data-remote'] = "true"
      anchor['data-type'] = "json"
      anchor['data-organizations'] = 'needs_organizations'
      age = anchor['data-age']
      name = anchor['data-spoken-name']
      anchor.inner_html = "%%" + name + " (#{age})" + "%%" if name
      lds_id = anchor['data-id']
      @individuals_anchors[lds_id] = anchor.to_html if lds_id
    end
=end

    #counters for progress
    import_total = @households.length + @individuals_anchors.length

    @user.progress_message = 'Importing Members'
    @user.save

    @individuals_anchors.each do |lds_id, html_anchor|
      #attempt to retrieve or create member
      member = Member.find_by_lds_id(lds_id)
      member = create_member(lds_id) unless member
      next unless member

      #if member was created / exists
      member_comments = member.comments.all
      user_has_not_seen = member_comments.any? do |comment|
        next if comment.private
        comment.viewed_by.exclude? @user.lds_id
      end
      #ORGANIZATION
      row_organizations = member.organizations.join(";")
      html_anchor.sub! 'needs_organizations', row_organizations

      #TAGS
      tags_html = ""
      member.tags.each do |tag|
        next if tag.organization != "All" &&
          tag.organization != "Internal" &&
          tag.organization != @user.organization
        tag_history = TagHistory.where(member_id: member.id, tag_id: tag.id).first
        next unless tag_history.active?



        tags_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"
      end

      @members_html[lds_id] = %Q(
        <tr data-id='#{lds_id}'
        data-row-type='member'
        data-head='needs_head_of_household'
        data-organization='#{row_organizations}'
        class='needs_odd_or_even known_or_unknown caret-hide' >
        <td class='household-caret'></td>
        <td class='member-name #{user_has_not_seen ? 'unseen' : ''}'>
        #{html_anchor}
        </td>
        <td class='table-tags'>#{tags_html}</td>
        <td class='table-comments'>
        <i class='fa fa-comment fa-lg'></i>
        <span class='comment-number'>
        #{member.comments.where(private: false).count}
        </span>
        </td>
        </tr>
      )
      @user.table_progress += 1.0 / import_total * 100
      @user.save
    end

    #make an empty anchor for non members to borrow and stick it in the member rows
    @members_html['non-member-template'] = %Q(
      <tr data-row-type='member'
      data-head='needs_head_of_household'
      class='needs_odd_or_even known_or_unknown caret-hide' >
      <td class='household-caret'></td>
      <td class='member-name'>
        <a href="#" class="modal-link" data-id="needs_id"
           data-spoken-name="needs_spoken_name" data-row-type="member"
           data-remote="true" data-type="json">
          needs_spoken_name
        </a>
      </td>
      <td class='table-tags'>needs_tags</td>
      <td class='table-comments'>
      <i class='fa fa-comment fa-lg'></i>
      <span class='comment-number'>
      needs_comments_count
      </span>
      </td>
      </tr>
    )

    #Also for non-members, we'll want the directory member-list since
    #it lists households including non-members
    if TESTING
      result = File.read(@path + "/dir-member-list.json")
    else
      add = "https://www.lds.org/directory/services/ludrs/mem/member-list/2968"
      result = @agent.get(add).body
    end
    @dir_member_list = JSON.parse(result)


    @table_body = ''
    # IMPORTANT
    # household-members is unit-level list of household members
    # householdProfile is individual household info
    # memberInformation
    # examples
    #  - Part-member-family, Mom is not a member
    #    * household-members['coupleName'] = Dad & Mom
    #    * household-members['familyMembers'] does not have mom
    #    * household-members['headOfHouseholdId'] = dad's id
    #    * householdProfile['headOfHousehold']['individualId'] = dad_lds_id
    #    * householdProfile['spouse']['individualId'] = -1
    #
    #  - Part-member-family, dad is not a member
    #    * others same
    #    * household-members['headOfHouseholdId'] = Mom's lds_id
    #    * householdProfile['headOfHousehold']['individualId'] is -1
    @user.progress_message = 'Importing Households'
    @user.save
    #HOUSEHOLDS
    @households.each_with_index do |household_members, index|
      lds_id = household_members["headOfHouseholdId"].to_s

      #attempt to create / retrieve household
      household = Household.find_by_lds_id(lds_id)
      household = create_household(lds_id, household_members) unless household
      next unless household
      @couple_name = household_members["coupleName"]
      #COMMENTS
      household_comments = household.comments.all
      user_has_not_seen = household_comments.any? do |comment|
        next if comment.private
        comment.viewed_by.exclude? @user.lds_id
      end

      row_class = index.even? ? "even" : "odd"

      #TAGS
      tags_html = ""
      household.tags.each do |tag|
        next if tag.organization != "All" &&
          tag.organization != "Internal" &&
          tag.organization != @user.organization
        tag_history = TagHistory.where(household_id: household.id, tag_id: tag.id).first
        next unless tag_history.active?
        tags_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"
      end

      #create row
      @table_body += %Q( <tr data-row-type='household' data-id='#{lds_id}' class='#{row_class} #{household.known? ? "known" : "unknown"}' )

      #add caret if multi-member house, add data-age if not
      if household.members.count > 1
        @table_body += %Q(>
        <td class='household-caret'>
        <a href="#" class='caret-button-right' data-id='#{lds_id}'>
        <i class="fa fa-caret-right fa-lg btn"></i>
        </a>
        </td>)
      else
        house_html = @individuals_anchors[lds_id]
        member = Member.find_by_lds_id(household.lds_id)
        if member
          row_organizations = member.organizations
          @table_body += %Q(
          data-organization='#{row_organizations}'
          )
        end
        @table_body += "><td class='household-caret'></td>"
      end

      @table_body += %Q(<td class='household-name #{user_has_not_seen ? 'unseen' : ''}'>)
      # if house_html means "if solo household". It's broken-up like this since
      # we have some folks in householdProfile that aren't on the lists. Since
      # these may get out of sync from time to time I have to have these kinds
      # of safe gaurds. :(
      if house_html
        house_html.sub!(/%%.*%%/, @couple_name)
        house_html.sub!('member', 'member-household')
        @table_body += house_html
      else
        @table_body += %Q(
        <a href="#"
        data-row-type='household'
        data-id='#{lds_id}'
        data-household-name='#{@couple_name}'
        data-remote="true"
        data-type="json"
        class="modal-link">
          #{@couple_name}
          </a>)
      end

      @table_body += %Q(
        </td>
        <td class='table-tags'>#{tags_html}</td>
        <td class='table-comments'>
        <i class='fa fa-comment fa-lg'></i>
        <span class='comment-number'>
        #{household.comments.where(private: false).count}
        </span>
        </td>
        </tr>
      )
      # ADD MEMBER ROWS IF APPLICABLE
      if household.members.count > 1
        household.members.reverse_each do |member|
          member_id = member.lds_id
          if member_id.include? 'NM'
            add_non_member(member, row_class)
          else #not a non member
            next if @members_html[member_id] == nil #this shouldn't get called, but it does in tests since households are not in sync with member lists
            html = @members_html[member_id].sub('needs_head_of_household',lds_id)
            html.sub!('needs_odd_or_even', row_class)
            known_or_unknown = household.known? ? "known" : "unknown"
            html.sub!('known_or_unknown', known_or_unknown)
            html.gsub!('%%','')
            @table_body += html
          end

        end #reverse household members
      end #if household members exist
      @user.table_progress += 1.0 / import_total * 100
      @user.save
    end #households.each
    @user.progress_message = 'Done!'
    @user.save
    @table += @table_body
    @table += '</tbody></table>'
    @user.table_ready = true
    @user.table_progress = 100
    @user.table = @table
    @user.save
  end

  def get_address(lds_id)
    if TESTING
      html = File.read(@path + "/householdProfile.json")
    else
      html = @agent.get("https://www.lds.org/directory/services/ludrs/mem/householdProfile/#{lds_id}").body
    end
    household_profile = JSON.parse(html)
    if household_profile["householdInfo"]
      json_address = household_profile["householdInfo"]["address"]
      if json_address.respond_to? :[]
        address = []
        %w(addr1 addr2 addr3 addr4 addr5).each do |add|
          address << json_address[add] if json_address[add] != ''
        end
        address = address.join(";")
      else
        address = 'unknown'
      end
    else
      address = "not logged in"
    end
  end

  def add_non_member(member, row_class)
    non_member = member
    household = member.household
    head_lds_id = household.lds_id
    household_info = @dir_member_list.find do |household|
      household["headOfHouseIndividualId"].to_s == head_lds_id
    end

    tags_html = ""
    non_member.tags.each do |tag|
      tags_html += "<span class='label label-#{tag.color}' >#{tag.body}</span>"
    end

    if household_info['headOfHouse']['individualId'] == -1
      name = household_info['headOfHouse']['preferredName']
    else
      name = household_info['spouse']['preferredName']
    end if household_info

    name = "UNKNOWN" unless household_info

    #Sub Template Row Info
    html = @members_html['non-member-template'].clone
    html.sub!('needs_head_of_household',head_lds_id)
    html.sub!('needs_odd_or_even', row_class)
    known_or_unknown = household.known? ? "known" : "unknown"
    html.sub!('known_or_unknown', known_or_unknown)
    #Sub Template Anchor Info
    html.sub!('needs_id', non_member.lds_id)
    html.gsub!('needs_spoken_name', name.split(',').reverse.join(' ').strip)
    #TAGS and COMMENTS
    html.sub!('needs_tags', tags_html)
    html.sub!('needs_comments_count', non_member.comments.count.to_s)

    @table_body += html
  end

  def handle_auth
    get_member_list unless @member_list

    #check that member list is well formed, i.e. I'm afraid this prop## stuff is fragile
    m = @member_list.match(/(prop2 = )(.*?);/)
    ward_id = m[2]
    page_valid = ward_id == "'2968:First Ward'"

    case
    when @member_list.include?("<title>Member List</title>") && page_valid && in_ward?
      :authorized
    when @member_list.include?("<title>Member List</title>") && !in_ward?
      :wrong_ward
    when @member_list.include?("<title>Access Denied</title>")
      :not_authorized
    when @member_list.include?("<title>Sign in</title>")
      :bad_credentials
    end
  end

  def can_fix?
    #find user, we'll check his/her id for reference
    user unless @user
    lds_id = @user.lds_id
    #fetch mls profile to see if birthPlace exists. Only higher ups see this info.
    if TESTING
      html = File.read(@path + "/profile.html")
    else
      html = @agent.get("https://www.lds.org/mls/mbr/records/member-profile/#{lds_id}?lang=eng").body
    end
    html.exclude?("birthPlace\":null")
  end

  def fix_that_which(needs_fixin)
    #moh =  member or household
    needs_fixin.each do |moh|
      lds_id = moh.lds_id
      if TESTING
        html = File.read(@path + "/profile.html")
      else
        html = @agent.get("https://www.lds.org/mls/mbr/records/member-profile/#{lds_id}?lang=eng").body
      end
      moh_json =  html.match(/(memberProfile.individual = )({.*})/)
      moh_info = JSON.parse(moh_json[2])

      if moh_info["formattedMoveDate"]
        move_in_date = Date.parse(moh_info["formattedMoveDate"])
        moh.moved_in = move_in_date
        moh.move_type = "moved-in"
      end
      # if that failed, then they may have been born into the ward
      if moh_info["formattedMoveDate"] == nil && moh_info["formattedBirthDate"]
        birth_date = Date.parse(moh_info["formattedBirthDate"])
        moh.moved_in = birth_date
        moh.move_type = "born"
      end
      # at this point, we know that we can import but it's failing
      # so we'll just set it to unknown
      if moh.moved_in == nil
        moh.moved_in = Time.now - 60*60*24*365.25*5
        moh.move_type = "unknown"
      end
      moh.save
    end
  end

  def in_ward?
    if TESTING
      cuws = File.read(@path + "/current-user-ward-stake.json")
    else
      cuws_add = "https://www.lds.org/directory/services/ludrs/unit/current-user-ward-stake/"
      cuws = @agent.get(cuws_add).body
    end
    user_ward = JSON.parse(cuws)["wardUnitNo"]
    user_ward == 2968
  end

  def session_still_valid?
    get_member_list unless @member_list
    @member_list.include?("<title>Member List</title>")
  end

end
