class Messages::Facebook::CommentBuilder < Messages::Messenger::MessageBuilder
    attr_reader :comment

    def initialize(comment)
        super()
        @comment = comment

        messenger_channel = Channel::FacebookPage.where(page_id: @comment.page_id)
        @inbox = ::Inbox.find_by(channel: messenger_channel)
    end

    def perform
        return if @inbox.channel.reauthorization_required?

        ActiveRecord::Base.transaction do
            ensure_contact if contacts_first_message?(message_source_id)
            build_message
        end
    rescue Koala::Facebook::AuthenticationError
        @inbox.channel.authorization_error!
    rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
        true
    end

    def ensure_contact
        begin
            k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
            result = k.get_object(message_source_id) || {}
        rescue Koala::Facebook::AuthenticationError
            debugger
            @inbox.channel.authorization_error!
            raise
        rescue StandardError, Koala::Facebook::ClientError => e
            result = {}
            ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
        end
        find_or_create_contact(result)
    end

    def find_or_create_contact(user)
        @contact_inbox = @inbox.contact_inboxes.where(source_id: user['id']).first
        @contact = @contact_inbox.contact if @contact_inbox
        return if @contact

        @contact_inbox = @inbox.channel.create_contact_inbox(
        user['id'], user['name']
        )

        @contact = @contact_inbox.contact
        Avatar::AvatarFromUrlJob.perform_later(@contact, user['profile_pic']) if user['profile_pic']
    end

    def contacts_first_message?(message_source_id)
        @inbox.contact_inboxes.where(source_id: message_source_id).empty?
    end


    def build_message
        @message = conversation.messages.create!(message_params)
    end

    def conversation
        @conversation ||= Conversation.find_by(conversation_params) || build_conversation
    end

    def conversation_params
        koala = Koala::Facebook::API.new(@inbox.channel.page_access_token)
        result = koala.get_object(@comment.post_id, { fields: "id,message,full_picture"})

        {
          account_id: @inbox.account_id,
          inbox_id: @inbox.id,
          contact_id: contact.id,
          additional_attributes: {
            type: 'facebook_comment_message',
            post_id: @comment.post_id,
            message: result['message'],
            media_url: result['full_picture']        
          }
        }
    end

    def build_conversation
        @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)
        Conversation.create!(conversation_params.merge(
                               contact_inbox_id: @contact_inbox.id
                             ))
    end

    def contact
        @contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
    end

    def message_params
        {
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id,
            message_type: message_type,
            source_id: message_identifier,
            content: message_content,
            sender: contact
        }
    end

    def message_source_id
        @comment.from_id
    end

    def message_type
        :incoming
    end

    def message_content
        @comment.text
    end

    def message_identifier
        @comment.comment_id
    end
end