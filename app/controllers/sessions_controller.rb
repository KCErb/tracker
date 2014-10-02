#encoding utf-8
class SessionsController < ApplicationController
  def new
  end
  
  def create
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
    web_address = "https://www.lds.org/mls/mbr/records/member-list?lang=eng"
    @res = @agent.get(web_address).body
    render 'new'
  end

  def destroy
  end
end
