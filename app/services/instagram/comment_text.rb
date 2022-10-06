class Instagram::CommentText < Instagram::WebhooksBaseService
  include HTTParty

  attr_reader :comment

  base_uri 'https://graph.facebook.com/v11.0/'

  def initialize(instagram_id, comment)
    super()
    @comment = comment
    @instagram_id = instagram_id
  end

  def perform
    Rails.logger.info("Creating comment #{@comment}")
    inbox_channel(@instagram_id)

    return if @inbox.blank?

    contact_id = comment[:value][:from][:id]
    is_post_back = contact_id === @instagram_id
    if !is_post_back
      ensure_contact(contact_id) if contacts_first_message?(contact_id)

      create_message
    end
  end

  def create_message
    Messages::Instagram::CommentBuilder.new(@comment, @inbox).perform
  end
end
