class ScraperWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(cookies)
    scraper = Scraper.new(cookies)
    scraper.create_table
    scraper = nil
  end
end
