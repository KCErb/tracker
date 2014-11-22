class TestWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(time)
    puts "Going to sleep now."
    sleep time
    puts "I'm awake!"
  end
end
