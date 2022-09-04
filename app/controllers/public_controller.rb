# TODO: we should switch to ActionController::API for the base classes
# One of the specs is failing when I tried doing that, lets revisit in future
class PublicController < ActionController::Base
  include RequestExceptionHandler
  skip_before_action :verify_authenticity_token
  before_action :set_global_config, only: [:terms, :privacy]

  layout 'public'

  def terms; end
  def privacy; end

  private
    def set_global_config
      @global_config = GlobalConfig.get('LOGO_THUMBNAIL', 'BRAND_NAME', 'WIDGET_BRAND_URL', 'DIRECT_UPLOADS_ENABLED')
    end

end
