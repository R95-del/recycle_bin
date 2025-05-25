# frozen_string_literal: true

module RecycleBin
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    before_action :authorize_access

    layout 'recycle_bin/application'

    protected

    # Helper method to handle RecycleBin-specific errors gracefully
    def handle_recycle_bin_error(error)
      log_error(error)
      error_message = user_friendly_error_message(error)
      respond_with_error(error_message)
    end

    # Helper method to check if the current request is for JSON
    def json_request?
      request.format.json?
    end

    # Helper method to safely constantize model names
    def safe_constantize_model(model_name)
      return nil unless model_name.present?

      model_class = model_name.constantize
      model_class < ActiveRecord::Base ? model_class : nil
    rescue NameError
      nil
    end

    # Helper method to format timestamps for consistent display
    def format_timestamp(timestamp)
      return 'N/A' unless timestamp

      timestamp.strftime('%B %d, %Y at %I:%M %p')
    end

    # Helper to check current page for navigation
    def current_page?(path)
      request.path == path
    end
    helper_method :current_page?

    private

    def authorize_access
      return true unless RecycleBin.config.authorization_method

      return if instance_eval(&RecycleBin.config.authorization_method)

      if defined?(main_app)
        redirect_to main_app.root_path, alert: 'Access denied.'
      else
        render plain: 'Access denied.', status: :forbidden
      end
    end

    def log_error(error)
      return unless Rails.logger

      Rails.logger.error "RecycleBin Error: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if error.backtrace
    end

    def user_friendly_error_message(error)
      case error
      when ActiveRecord::RecordNotFound
        'The requested item could not be found.'
      when NameError
        'Invalid model type specified.'
      when NoMethodError
        'This operation is not supported for this item type.'
      else
        'An unexpected error occurred. Please try again.'
      end
    end

    def respond_with_error(message)
      respond_to do |format|
        format.html { redirect_with_flash_error(message) }
        format.json { render_json_error(message) }
      end
    end

    def redirect_with_flash_error(message)
      flash[:alert] = message
      redirect_to main_app.respond_to?(:recycle_bin_path) ? main_app.recycle_bin_path : root_path
    end

    def render_json_error(message)
      render json: {
        message: message,
        status: 'error',
        error_type: 'RecycleBinError'
      }, status: :internal_server_error
    end
  end
end
