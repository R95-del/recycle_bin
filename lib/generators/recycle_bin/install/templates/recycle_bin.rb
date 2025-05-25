# RecycleBin Configuration
RecycleBin.configure do |config|
  # Enable web interface (default: true)
  config.enable_web_interface = true

  # Uncomment and customize as needed:
  
  # Auto-cleanup items after specified time (default: nil - disabled)
  # config.auto_cleanup_after = 30.days

  # Method to get current user for audit trail  
  # config.current_user_method = :current_user

  # Items per page in web interface
  # config.items_per_page = 25

  # Authorization callback
  # config.authorize_with do |controller|
  #   # Example: Only allow admins
  #   controller.current_user&.admin?
  # end
end