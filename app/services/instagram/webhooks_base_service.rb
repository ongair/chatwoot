class Instagram::WebhooksBaseService
  private

  def inbox_channel(instagram_id)
    messenger_channel = Channel::FacebookPage.where(instagram_id: instagram_id)
    @inbox = ::Inbox.find_by(channel: messenger_channel)
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

  def ensure_contact(ig_scope_id)
    begin
      k = Koala::Facebook::API.new(@inbox.channel.page_access_token) if @inbox.facebook?
      result = k.get_object(ig_scope_id) || {}
    rescue Koala::Facebook::AuthenticationError
      @inbox.channel.authorization_error!
      raise
    rescue StandardError, Koala::Facebook::ClientError => e
      result = {}
      ChatwootExceptionTracker.new(e, account: @inbox.account).capture_exception
    end

    find_or_create_contact(result)
  end

  def contacts_first_message?(ig_scope_id)
    @inbox.contact_inboxes.where(source_id: ig_scope_id).empty? && @inbox.channel.instagram_id.present?
  end
end
