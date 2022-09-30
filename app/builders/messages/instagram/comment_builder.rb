class Messages::Instagram::CommentBuilder < Messages::Messenger::MessageBuilder
  attr_reader :comment

  def initialize(comment, inbox)
    super()
    @inbox = inbox
    @comment = comment
  end

  def perform
    return if @inbox.channel.reauthorization_required?

    ActiveRecord::Base.transaction do
      build_message
    end
  rescue Koala::Facebook::AuthenticationError
    @inbox.channel.authorization_error!
  # raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    true
  end

  def build_message
    @message = conversation.messages.create!(message_params)
  end

  def contact
    @contact ||= @inbox.contact_inboxes.find_by(source_id: message_source_id)&.contact
  end

  def conversation
    @conversation ||= Conversation.find_by(conversation_params) || build_conversation
  end

  def message_identifier
    @comment[:value][:id]
  end

  def message_source_id
    @comment[:value][:from][:id]
  end

  def message_type
    :incoming
  end

  def message_content
    @comment[:value][:text]
  end

  def build_conversation
    @contact_inbox ||= contact.contact_inboxes.find_by!(source_id: message_source_id)
    Conversation.create!(conversation_params.merge(
                           contact_inbox_id: @contact_inbox.id
                         ))
  end

  def conversation_params
    {
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      contact_id: contact.id,
      additional_attributes: {
        type: 'instagram_comment_message'
      }
    }
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
end
