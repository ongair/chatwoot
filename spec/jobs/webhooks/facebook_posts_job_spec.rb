require 'rails_helper'

RSpec.describe Webhooks::FacebookPostsJob, type: :job do
    subject(:posts_webhook) { described_class }

    before do
        stub_request(:post, /graph.facebook.com/)
        stub_request(:get, 'https://www.example.com/test.jpeg')
          .to_return(status: 200, body: '', headers: {})
    end

    let(:fb_object) { double }
    let!(:account) { create(:account) }
    let!(:facebook_channel) { create(:channel_instagram_fb_page, account: account, page_id: 'chatwoot-app-user-id-1') }
    let!(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account, greeting_enabled: false) }
    let(:return_onject) do
        { name: 'Jane',
          id: 'Sender-id-1',
          account_id: facebook_inbox.account_id,
          profile_pic: 'https://chatwoot-assets.local/sample.png' }
    end

    describe '#perform' do
        let!(:comment_params) { build(:incoming_fb_comment_message).with_indifferent_access }

        it 'handles creation of a post comment' do
            allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
            allow(fb_object).to receive(:get_object).and_return(
                return_onject.with_indifferent_access
            )
            posts_webhook.perform_now(comment_params.to_json)
            facebook_inbox.reload
            expect(facebook_inbox.contacts.count).to be 1
            expect(facebook_inbox.messages.count).to be 1
        end
    end
end