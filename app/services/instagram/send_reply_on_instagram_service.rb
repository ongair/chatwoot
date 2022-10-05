class Instagram::SendReplyOnInstagramService < Base::SendOnChannelService
    include HTTParty

    pattr_initialize [:message!]

    base_uri 'https://graph.facebook.com/v11.0/'

    private

    delegate :additional_attributes, to: :contact


    def perform_reply
        access_token = channel.page_access_token
        query = { access_token: access_token }

        response = HTTParty.post(
            "https://graph.facebook.com/v11.0/#{conversation.additional_attributes['post_id']}/comments/#{last_incoming_message.source_id}?replies",
            body: message_params,
            :debug_output => $stdout,
            query: query
        )
    end

    def last_incoming_message
        conversation.messages.incoming.last
    end

    def message_params
        {
            hide: false,
            message: message.content
        }
    end

    def channel_class
        Channel::FacebookPage
    end

    def config
        Facebook::Messenger.config
    end
end
