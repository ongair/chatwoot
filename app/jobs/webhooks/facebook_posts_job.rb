class Webhooks::FacebookPostsJob < ApplicationJob
    queue_as :default
  
    def perform(value)
    #   response = ::Integrations::Facebook::MessageParser.new(message)
    #   ::Integrations::Facebook::MessageCreator.new(response).perform
        Rails.logger.info "Comments job #{value}"
    end
  end
  