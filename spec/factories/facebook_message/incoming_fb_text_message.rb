# frozen_string_literal: true

FactoryBot.define do
  factory :incoming_fb_text_message, class: Hash do
    messaging do
      { sender: { id: '3383290475046708' },
        recipient: { id: '117172741761305' },
        message: { mid: 'm_KXGKDUpO6xbVdAmZFBVpzU1AhKVJdAIUnUH4cwkvb_K3iZsWhowDRyJ_DcowEpJjncaBwdCIoRrixvCbbO1PcA', text: 'facebook message' } }
    end

    initialize_with { attributes }
  end

  factory :incoming_fb_comment_message, class: Hash do
    value do
      {
        value: {
          from: {
            id: 'Sender-id-1',
            name: 'User'
          },
          post: {
            status_type: 'mobile_status_update',
            permalink_url: 'https://www.facebook.com/',
            id: '3383290475046708_post_id'
          },
          page_id: 'chatwoot-app-user-id-1',
          message: 'Comment',
          post_id: '3383290475046708_post_id',
          item: 'comment',
          comment_id: 'comment_id',
          parent_id: '3383290475046708_post_id'
        }
      }
    end
    initialize_with { attributes }
  end
end
