class Instagram::CommentText < Instagram::WebhooksBaseService
    include HTTParty

    attr_reader :comment

    base_uri 'https://graph.facebook.com/v11.0/'

    def initialize(comment)
        super()
        @comment = comment
    end

    def perform
        Rails.logger.info("Creating comment #{@comment}")
    end
end