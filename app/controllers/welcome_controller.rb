class WelcomeController < ApplicationController
  skip_before_action :require_login, only: :index
  def index
    logger.info "log this message"
    logger.info "log this message"
    logger.info "log this message"
  end
end
