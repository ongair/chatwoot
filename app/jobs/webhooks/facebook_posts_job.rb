class Webhooks::FacebookPostsJob < ApplicationJob
    queue_as :default
  
    def perform(value)
        comment = ::Integrations::Facebook::CommentParser.new(value)
        ::Integrations::Facebook::CommentCreator.new(comment).perform
    end
  end
  