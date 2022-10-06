class Webhooks::InstagramEventsJob < ApplicationJob
  queue_as :default

  include HTTParty

  base_uri 'https://graph.facebook.com/v11.0/me'

  # @return [Array] We will support further events like reaction or seen in future
  SUPPORTED_EVENTS = [:message].freeze

  # @see https://developers.facebook.com/docs/messenger-platform/instagram/features/webhook
  def perform(entries)
    @entries = entries

    @entries.each do |entry|
      entry[:messaging] && entry[:messaging].each do |messaging|
        send(@event_name, messaging) if event_name(messaging)
      end

      entry[:changes] && entry[:changes].each do |change|
        comment(entry[:id], change)
      end
    end
  end

  private

  def event_name(messaging)
    @event_name ||= SUPPORTED_EVENTS.find { |key| messaging.key?(key) }
  end

  def message(messaging)
    ::Instagram::MessageText.new(messaging).perform
  end

  def comment(instagram_id, comment)
    Rails.logger.info("Adding comment", comment)
    ::Instagram::CommentText.new(instagram_id, comment).perform
  end
end
