require 'rails_helper'
require 'webhooks/twitter'

describe Webhooks::InstagramEventsJob do
  subject(:instagram_webhook) { described_class }

  before do
    stub_request(:post, /graph.facebook.com/)
    stub_request(:get, 'https://www.example.com/test.jpeg')
      .to_return(status: 200, body: '', headers: {})
  end

  let!(:account) { create(:account) }
  let(:return_onject) do
    { name: 'Jane',
      id: 'Sender-id-1',
      account_id: instagram_inbox.account_id,
      profile_pic: 'https://chatwoot-assets.local/sample.png' }
  end
  let!(:instagram_channel) { create(:channel_instagram_fb_page, account: account, instagram_id: 'chatwoot-app-user-id-1') }
  let!(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account, greeting_enabled: false) }
  let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }
  let!(:test_params) { build(:instagram_test_text_event).with_indifferent_access }
  let!(:unsend_event) { build(:instagram_message_unsend_event).with_indifferent_access }
  let!(:attachment_params) { build(:instagram_message_attachment_event).with_indifferent_access }
  let!(:story_mention_params) { build(:instagram_story_mention_event).with_indifferent_access }
  let!(:comment_params) { build(:instagram_post_comment).with_indifferent_access }
  let(:fb_object) { double }

  describe '#perform' do
    context 'with direct_message params' do
      it 'creates incoming message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_onject.with_indifferent_access
        )
        instagram_webhook.perform_now(dm_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.conversations.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
      end

      it 'creates test text message in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_onject.with_indifferent_access
        )
        instagram_webhook.perform_now(test_params[:entry])

        instagram_inbox.reload
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.content).to eq('random_text')
        expect(instagram_inbox.messages.last.source_id).to eq('random_mid')
      end

      it 'handle instagram unsend message event' do
        create(:message,
               source_id: 'message-id-to-delete',
               inbox_id: instagram_inbox.id)
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          {
            name: 'Jane',
            id: 'Sender-id-1',
            account_id: instagram_inbox.account_id,
            profile_pic: 'https://chatwoot-assets.local/sample.png'
          }.with_indifferent_access
        )
        expect(instagram_inbox.messages.count).to be 1
        instagram_webhook.perform_now(unsend_event[:entry])

        expect(instagram_inbox.messages.last.content).to eq 'This message was deleted'
        expect(instagram_inbox.messages.last.reload.deleted).to be true
      end

      it 'creates incoming message with attachments in the instagram inbox' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_onject.with_indifferent_access
        )
        instagram_webhook.perform_now(attachment_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.contacts.count).to be 1
        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.attachments.count).to be 1
      end

      it 'creates incoming message with attachments in the instagram inbox for story mention' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        allow(fb_object).to receive(:get_object).and_return(
          return_onject.with_indifferent_access,
          { story:
            {
              mention: {
                link: 'https://www.example.com/test.jpeg',
                id: '17920786367196703'
              }
            },
            from: {
              username: 'Sender-id-1', id: 'Sender-id-1'
            },
            id: 'instagram-message-id-1234' }.with_indifferent_access
        )

        instagram_webhook.perform_now(story_mention_params[:entry])

        instagram_inbox.reload

        expect(instagram_inbox.messages.count).to be 1
        expect(instagram_inbox.messages.last.attachments.count).to be 1
      end

      it 'handles creation of a post comment' do
        allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
        instagram_webhook.perform_now(comment_params[:entry])
      end
    end
  end
end
