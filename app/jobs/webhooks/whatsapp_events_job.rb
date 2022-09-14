class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    Rails.logger.info(">>> Performing WhatsappEventsJob: #{params}")
    channel = find_channel_from_whatsapp_business_payload(params) || find_channel(params)
    Rails.logger.info(">>> Channel found #{channel}")
    return if channel.blank?

    case channel.provider
    when 'whatsapp_cloud'
      Rails.logger.info('>> Channel provider: whatsapp_cloud')
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    end
  end

  private

  def find_channel(params)
    Rails.logger.info(">> find_channel #{params[:phone_number]}")
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end

  def find_channel_from_whatsapp_business_payload(params)
    # for the case where facebook cloud api support multiple numbers for a single app
    # https://github.com/chatwoot/chatwoot/issues/4712#issuecomment-1173838350
    # we will give priority to the phone_number in the payload
    return unless params[:object] == 'whatsapp_business_account'

    get_channel_from_wb_payload(params)
  end

  def get_channel_from_wb_payload(wb_params)
    Rails.logger.info(">>> get_channel_from_wb_payload #{wb_params}")
    phone_number = "+#{wb_params[:entry].first[:changes].first.dig(:value, :metadata, :display_phone_number)}"
    phone_number_id = wb_params[:entry].first[:changes].first.dig(:value, :metadata, :phone_number_id)
    channel = Channel::Whatsapp.find_by(phone_number: phone_number)
    # validate to ensure the phone number id matches the whatsapp channel
    return channel if channel && channel.provider_config['phone_number_id'] == phone_number_id
  end
end
