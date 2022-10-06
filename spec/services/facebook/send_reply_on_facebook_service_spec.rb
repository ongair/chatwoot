require 'rails_helper'

describe Instagram::SendReplyOnInstagramService do
    subject(:send_reply_service) { described_class.new(message: message) }

    before do
        stub_request(:post, /graph.facebook.com/)
        create(:message, message_type: :incoming, inbox: fb_inbox, account: account, conversation: conversation)
    end

    let!(:account) { create(:account) }
    let!(:fb_channel) { create(:channel_instagram_fb_page, account: account) }
    let!(:fb_inbox) { create(:inbox, channel: fb_channel, account: account, greeting_enabled: false) }
    let!(:contact) { create(:contact, account: account) }
    let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: fb_inbox) }
    let(:conversation) { create(:conversation, contact: contact, inbox: fb_inbox, contact_inbox: contact_inbox, additional_attributes: { 'type' => 'facebook_comment_message', 'post_id' => 'fb_post_id' }) }
    let!(:incoming_message) { create(:message, conversation: conversation, message_type: 'incoming', inbox: fb_inbox, account: account, source_id: 'fb_comment_id' )}
    let(:response) { double }

    describe '#perform' do
        context 'with reply' do
            before do
                allow(Facebook::Messenger::Configuration::AppSecretProofCalculator).to receive(:call).and_return('app_secret_key', 'access_token')
            end

            it 'can send a message reply' do
                message = create(:message, message_type: 'outgoing', content: 'reply', inbox: fb_inbox, account: account, conversation: conversation)
                allow(HTTParty).to receive(:post).with('https://graph.facebook.com/v11.0/fb_comment_id/comments', {
                    body: {
                        message: 'reply'
                    },
                    :debug_output => $stdout,
                    query: {
                        access_token: fb_channel.page_access_token
                    }
                }).and_return(
                    {
                        'id': 'fb_reply_id'
                    }
                )

                response = ::Facebook::SendReplyOnFacebookService.new(message: message).perform
            end
        end
    end
end