# frozen_string_literal: true

module RecycleBin
  # Base controller for the RecycleBin engine
  # Inherits from ActionController::Base for standalone functionality
  # All RecycleBin controllers inherit from this base controller
  class ApplicationController < ActionController::Base
    # Skip CSRF protection for API operations since we're testing APIs
    skip_before_action :verify_authenticity_token

    # Add any common functionality for RecycleBin controllers here
    # This controller provides shared methods and error handling for all RecycleBin controllers

    protected

    # Helper method to handle RecycleBin-specific errors gracefully
    # This ensures consistent error handling across all RecycleBin controllers
    # @param error [StandardError] The error that occurred
    def handle_recycle_bin_error(error)
      # Log the error for debugging purposes
      Rails.logger&.error "RecycleBin Error: #{error.message}"
      Rails.logger.error error.backtrace.join("\n") if Rails.logger && error.backtrace

      # Provide user-friendly error messages
      error_message = case error
                      when ActiveRecord::RecordNotFound
                        'The requested item could not be found.'
                      when NameError
                        'Invalid model type specified.'
                      when NoMethodError
                        'This operation is not supported for this item type.'
                      else
                        'An unexpected error occurred. Please try again.'
                      end

      # Handle both HTML and JSON requests appropriately
      respond_to do |format|
        format.html do
          flash[:error] = error_message
          redirect_to recycle_bin.trash_index_path
        end
        format.json do
          render json: {
            message: error_message,
            status: 'error',
            error_type: error.class.name
          }, status: :internal_server_error
        end
      end
    end

    # Helper method to check if the current request is for JSON
    # Useful for determining response format in controllers
    def json_request?
      request.format.json?
    end

    # Helper method to safely constantize model names
    # Prevents errors when invalid model names are passed
    # @param model_name [String] The model name to constantize
    # @return [Class, nil] The model class or nil if invalid
    def safe_constantize_model(model_name)
      return nil unless model_name.present?

      begin
        model_class = model_name.constantize
        # Ensure it's an ActiveRecord model
        return model_class if model_class < ActiveRecord::Base
      rescue NameError
        # Invalid model name
      end

      nil
    end

    # Helper method to format timestamps for consistent display
    # @param timestamp [Time, DateTime] The timestamp to format
    # @return [String] Formatted timestamp string
    def format_timestamp(timestamp)
      return 'N/A' unless timestamp

      timestamp.strftime('%B %d, %Y at %I:%M %p')
    end
  end
end
